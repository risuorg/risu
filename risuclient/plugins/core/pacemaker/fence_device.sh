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

# long_name: Stonith device configuration
# description: Checks pacemaker stonith devices are configured
# priority: 400

# we can run this against fs snapshot or live system

[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

is_required_file "${RISU_ROOT}/etc/corosync/corosync.conf"

if [[ "x$RISU_LIVE" == "x0" ]]; then
    if is_active "pacemaker"; then
        for CLUSTER_DIRECTORY in "pacemaker" "cluster"; do
            if [[ -d "${RISU_ROOT}/sos_commands/${CLUSTER_DIRECTORY}" ]]; then
                PCS_DIRECTORY="${RISU_ROOT}/sos_commands/${CLUSTER_DIRECTORY}"
            fi
        done
        is_required_file "${PCS_DIRECTORY}/pcs_config"
        if is_lineinfile "class=stonith" "${PCS_DIRECTORY}/pcs_config"; then
            exit ${RC_OKAY}
        else
            echo "NO stonith devices configured" >&2
            exit ${RC_FAILED}
        fi
    else
        echo "pacemaker is not running on this node" >&2
        exit ${RC_SKIPPED}
    fi

elif [[ "x$RISU_LIVE" == "x1" ]]; then
    pacemaker_status=$(systemctl is-active pacemaker || :)
    if [[ $pacemaker_status == "active" ]]; then
        if pcs stonith show | grep -q "NO stonith devices configured"; then
            echo "No stonith devices configured" >&2
            exit ${RC_FAILED}
        else
            exit ${RC_OKAY}
        fi
    else
        echo "pacemaker is not running on this node" >&2
        exit ${RC_SKIPPED}
    fi
fi
