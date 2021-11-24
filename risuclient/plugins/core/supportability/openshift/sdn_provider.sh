#!/bin/bash

# Copyright (C) 2018, 2020, 2021 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

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

# long_name: reports non supported SDN provider on OCP
# description: reports non supported SDN provider on OCP
# priority: 300

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

RHPLUGIN="redhat/openshift"

OCPVERSION=$(discover_ocp_version)

if [[ ${OCPVERSION} == "0" ]]; then
    echo "Not running on OCP node" >&2
    exit ${RC_SKIPPED}
else
    is_required_file ${RISU_ROOT}/etc/origin/master/master-config.yaml
    NETWORKPLUGIN=$(grep 'networkPluginName' ${RISU_ROOT}/etc/origin/master/master-config.yaml)

    if [[ -z ${NETWORKPLUGIN} ]]; then
        echo "configured OpenShift network-plugin: ${NETWORKPLUGIN}" >&2

        if [[ ! ${NETWORKPLUGIN} =~ ${RHPLUGIN} ]]; then
            echo "Plugin ${NETWORKPLUGIN} is not a supported plugin by Red Hat!" >&2
            exit ${RC_INFO}
        fi
    fi
fi
exit ${RC_OKAY}
