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

# we can run this against fs snapshot or live system

# long_name: Failed actions
# description: Check if there are pacemaker failed actions
# priority: 800

is_required_file "${CITELLUS_ROOT}/etc/corosync/corosync.conf"

if [[ "x$CITELLUS_LIVE" = "x1" ]]; then
    pacemaker_status=$(systemctl is-active pacemaker || :)
    if [[ "$pacemaker_status" = "active" ]]; then
        if pcs status | grep -q "Failed Actions"; then
            pcs status | awk -F" " '/^\*/ {print $2}' >&2
            exit ${RC_FAILED}
        else
            echo "no failed actions detected" >&2
            exit ${RC_OKAY}
        fi
    else
        echo "pacemaker is not running on this node" >&2
        exit ${RC_SKIPPED}
    fi
elif [[ "x$CITELLUS_LIVE" = "x0" ]]; then
    if is_active "pacemaker"; then
        for CLUSTER_DIRECTORY in "pacemaker" "cluster"; do
            if [[ -d "${CITELLUS_ROOT}/sos_commands/${CLUSTER_DIRECTORY}" ]]; then
                PCS_DIRECTORY="${CITELLUS_ROOT}/sos_commands/${CLUSTER_DIRECTORY}"
            fi
        done
        is_required_file "${PCS_DIRECTORY}/pcs_status"
        if is_lineinfile "Failed Actions" "${PCS_DIRECTORY}/pcs_status"; then
            awk -F" " '/^\*/ {print $2}'  "${PCS_DIRECTORY}/pcs_status" >&2
            exit ${RC_FAILED}
        else
            echo "no failed actions detected" >&2
            exit ${RC_OKAY}
        fi
    else
        echo "pacemaker is not running on this node" >&2
        exit ${RC_SKIPPED}
    fi
fi
