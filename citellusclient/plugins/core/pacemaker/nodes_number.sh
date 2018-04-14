#!/bin/bash

# Copyright (C) 2017   Robin Černín (rcernin@redhat.com)

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

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

# long_name: Number of pacemaker nodes
# description: Checks number of pacemaker nodes
# priority: 800

# we can run this against fs snapshot or live system

count_nodes(){
    if [[ ! "$(echo $(( (NUM_NODES-1) % 2 )))" -eq  "0" ]]; then
        echo "${NUM_NODES}" >&2
        exit ${RC_FAILED}
    elif [[ "x$NUM_NODES" = "x1" ]]; then
        echo "${NUM_NODES}" >&2
        exit ${RC_FAILED}
    else
        exit ${RC_OKAY}
    fi
}

is_required_file "${CITELLUS_ROOT}/etc/corosync/corosync.conf"

if ! is_active pacemaker; then
    echo "pacemaker is not running on this node" >&2
    exit ${RC_SKIPPED}
fi

if [[ "x$CITELLUS_LIVE" = "x1" ]];  then
    NUM_NODES=$(pcs config |  awk '/Pacemaker Nodes/ {getline; print $0}' | wc -w)
    count_nodes
elif [[ "x$CITELLUS_LIVE" = "x0" ]];  then
    if is_active "pacemaker"; then
        for CLUSTER_DIRECTORY in "pacemaker" "cluster"; do
            if [[ -d "${CITELLUS_ROOT}/sos_commands/${CLUSTER_DIRECTORY}" ]]; then
                PCS_DIRECTORY="${CITELLUS_ROOT}/sos_commands/${CLUSTER_DIRECTORY}"
            fi
        done
        is_required_file "${PCS_DIRECTORY}/pcs_config"
        NUM_NODES=$(awk '/Pacemaker Nodes/ {getline; print $0}' "${PCS_DIRECTORY}/pcs_config" | wc -w)
        count_nodes
    fi
fi
