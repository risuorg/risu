#!/bin/bash

# Copyright (C) 2018   Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)

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

# we can run this against fs snapshot or live system

# long_name: Check OSP11+ and number of DHCP agents
# description: Checks for invalid OSP11+ dhcp_agents_per_network
# priority: 500

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

is_required_file "${CITELLUS_ROOT}/etc/neutron/neutron.conf"
is_required_file "${CITELLUS_ROOT}/etc/corosync/corosync.conf"

# Find release
RELEASE=$(discover_osp_version)

if [[ "$RELEASE" -le "10" ]]; then
    echo "This affects only OSP11 onwards" >&2
    exit ${RC_SKIPPED}
fi

for package in tripleo-heat-templates openstack-tripleo-heat-templates python-tripleoclient; do
    if is_pkg ${package} > /dev/null 2>&1 ; then
        echo "Doesn't work on director" >&2
        exit ${RC_SKIPPED}
    fi
done

VALUE=$(iniparser ${CITELLUS_ROOT}/etc/neutron/neutron.conf DEFAULT dhcp_agents_per_network)


# Code from nodes_number.sh by Robin Černín (rcernin@redhat.com)
if ! is_active pacemaker; then
    echo "pacemaker is not running on this node" >&2
    exit ${RC_SKIPPED}
fi

if [[ "x$CITELLUS_LIVE" = "x1" ]];  then
    NUM_NODES=$(pcs config |  awk '/Pacemaker Nodes/ {getline; print $0}' | wc -w)
elif [[ "x$CITELLUS_LIVE" = "x0" ]];  then
    if is_active "pacemaker"; then
        for CLUSTER_DIRECTORY in "pacemaker" "cluster"; do
            if [[ -d "${CITELLUS_ROOT}/sos_commands/${CLUSTER_DIRECTORY}" ]]; then
                PCS_DIRECTORY="${CITELLUS_ROOT}/sos_commands/${CLUSTER_DIRECTORY}"
            fi
        done
        is_required_file "${PCS_DIRECTORY}/pcs_config"
        NUM_NODES=$(awk '/Pacemaker Nodes/ {getline; print $0}' "${PCS_DIRECTORY}/pcs_config" | wc -w)
    fi
fi

# Fake value if using defaults
if [[ "x${VALUE}" == 'x' ]]; then
    VALUE=${NUM_NODES}
fi

if [[ "${VALUE}" != "${NUM_NODES}" ]]; then
    echo $"Mismatch on dhcp_agents_per_network https://bugs.launchpad.net/tripleo/+bug/1752826" >&2
    exit ${RC_FAILED}
fi

exit ${RC_OKAY}
