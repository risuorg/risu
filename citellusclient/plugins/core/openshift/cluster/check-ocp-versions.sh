#!/bin/bash
# Copyright (C) 2018 Pablo Iranzo Gómez <Pablo.Iranzo@redhat.com>
# Copyright (C) 2018 Mario Vazquez <mavazque@redhat.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# long_name: Check OpenShift Versions
# description: Checks for different OpenShift versions running on the shame OCP Cluster
# priority: 500

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"


if [[ ! "x$CITELLUS_LIVE" = "x1" ]]; then
    FILE="${CITELLUS_ROOT}/sos_commands/kubernetes/kubectl_get_-o_json_nodes"
    is_required_file "${FILE}"

    LINES="$(grep kubeletVersion ${FILE} | sed -n "s/\",//gp" | sed -n "s/.*\(v[0-9]\+\?.[0-9]\+\?.[0-9]\+\?\+[a-zA-Z0-9].\+\)/\1/gp" | sort -u | wc -l)"

    if [[ "${LINES}" -gt 1 ]]; then
        echo "Multiple OpenShift versions found" >&2
        grep kubeletVersion ${FILE} | sed -n "s/\",//gp" | sed -n "s/.*\(v[0-9]\+\?.[0-9]\+\?.[0-9]\+\?\+[a-zA-Z0-9].\+\)/\1/gp" | sort -u >&2
        exit ${RC_FAILED}
    else
        exit ${RC_OKAY}
    fi

else
    # This test requires oc command and being authenticated on OCP

    # Sort for unique OCP versions on the output
    # Current output for oc get node is something like:
    # NAME         STATUS     ROLES     AGE       VERSION
    # localhost    Ready      <none>    7h        v1.9.1+a0ce1bc657
    # localhost2   Ready      <none>    7h        v1.9.1+a0ce1bc657

    which oc > /dev/null 2>&1
    RC=$?

    if [[ "x$RC" = "x0" ]]; then
        # Test connection to ocp
        _test=$(oc whoami 2>&1)
        RC=$?
        if [[ "x$RC" != "x0" ]]; then
            echo -e "ERROR connecting to OpenShift\n${_test}" >&2
            exit ${RC_SKIPPED}
        fi
    else
        echo "missing oc binaries" >&2
        exit ${RC_SKIPPED}
    fi
    # sudo oc get nodes --template='{{range .items}}{{ .status.nodeInfo.kubeletVersion}}{{"|"}}{{end}}' | sed "s/|/\n/g" | sed "/^$/d"
    OC_VERSIONS=$(oc get nodes --template='{{range .items}}{{ .status.nodeInfo.kubeletVersion}}{{"|"}}{{end}}')
    RC=$?
    if [[ "x$RC" = "x0" ]]; then
        OC_UNIQUE_VERSIONS_COUNT="$(echo $OC_VERSIONS | sed "s/|/\n/g" | sed "/^$/d" | sort -u | wc -l)"
        OC_UNIQUE_VERSIONS="$(echo $OC_VERSIONS | sort -u)"
        if [[ $OC_UNIQUE_VERSIONS_COUNT = 1 ]]; then
            echo "All nodes are running the same OpenShift version: ${OC_UNIQUE_VERSIONS}" >&2
            exit ${RC_OKAY}
        else
            echo "Multiple OpenShift versions found: $OC_UNIQUE_VERSIONS" >&2
            exit ${RC_FAILED}
        fi
    else
        echo "Error running oc command: $OC_VERSIONS" >&2
        exit ${RC_SKIPPED}
    fi
fi

echo "Test should have skipped before reaching this point" >&2
exit ${RC_FAILED}

