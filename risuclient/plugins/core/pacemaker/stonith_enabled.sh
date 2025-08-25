#!/bin/bash
# Copyright (C) 2021-2023 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

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

# long_name: Stonith configuration
# description: Checks for stonith enabled in cluster
# priority: 400

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

STONITHNOTENABLED=$"stonith is not enabled"

is_required_file "${RISU_ROOT}/etc/corosync/corosync.conf"

# we can run this against fs snapshot or live system

if [[ "x$RISU_LIVE" == "x1" ]]; then
    pacemaker_status=$(systemctl is-active pacemaker || :)
    if [[ $pacemaker_status == "active" ]]; then
        if pcs config | grep -q "stonith-enabled:.*false"; then
            echo "$STONITHNOTENABLED" >&2
            exit ${RC_FAILED}
        else
            exit ${RC_OKAY}
        fi
    else
        echo "pacemaker is not running on this node" >&2
        exit ${RC_SKIPPED}
    fi
elif [[ "x$RISU_LIVE" == "x0" ]]; then
    if is_active "pacemaker"; then
        for CLUSTER_DIRECTORY in "pacemaker" "cluster"; do
            if [[ -d "${RISU_ROOT}/sos_commands/${CLUSTER_DIRECTORY}" ]]; then
                PCS_DIRECTORY="${RISU_ROOT}/sos_commands/${CLUSTER_DIRECTORY}"
            fi
        done
        is_required_file "${PCS_DIRECTORY}/pcs_config"
        if is_lineinfile "stonith-enabled:.*false" "${PCS_DIRECTORY}/pcs_config"; then
            echo "$STONITHNOTENABLED" >&2
            exit ${RC_FAILED}
        else
            exit ${RC_OKAY}
        fi
    else
        echo "pacemaker is not running on this node" >&2
        exit ${RC_SKIPPED}
    fi
fi
