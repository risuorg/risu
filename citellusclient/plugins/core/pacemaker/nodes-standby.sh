#!/bin/bash

# Copyright (C) 2018 Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)

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

# long_name: Checks that nodes are not in standby
# description: Checks for nodes that are standby in cluster
# priority: 700

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

# we can run this against fs snapshot or live system
if [[ ${CITELLUS_LIVE} -eq 0 ]]; then
    for CLUSTER_DIRECTORY in "pacemaker" "cluster"; do
        if [[ -d "${CITELLUS_ROOT}/sos_commands/${CLUSTER_DIRECTORY}" ]]; then
            PCS_DIRECTORY="${CITELLUS_ROOT}/sos_commands/${CLUSTER_DIRECTORY}"
        fi
    done

    FILE="${PCS_DIRECTORY}/pcs_status"
elif [[ ${CITELLUS_LIVE} -eq 1 ]];then
    is_required_command "pcs"
    FILE=$(mktemp)
    trap "rm ${FILE}" EXIT
    pcs status > ${FILE}
fi

is_required_file ${FILE}
if is_lineinfile "Node.*: standby" ${FILE}; then
    echo "Nodes found in standby: " >&2
    grep "Node.*standby" ${FILE} >&2
    exit ${RC_FAILED}
fi
exit ${RC_OKAY}
