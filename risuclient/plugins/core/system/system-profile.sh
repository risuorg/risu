#!/bin/bash
# Copyright (C) 2020, 2021 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

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

# long_name: disk scheduler
# description: Checks for proper disk scheduler
# priority: 500

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

if [[ ${RISU_LIVE} -eq 0 ]]; then
    FILE="${RISU_ROOT}/sos_commands/tuned/tuned-adm_list"
elif [[ ${RISU_LIVE} -eq 1 ]]; then
    FILE=$(mktemp)
    trap "rm ${FILE}" EXIT
    LANG=C tuned-adm list >${FILE} 2>&1
fi

is_required_file ${FILE}

if is_virtual; then
    # Virtual machine, check if profile is virtual-guest
    SYSPROFILE=$(cat ${FILE} | grep ^"Current" | cut -d ":" -f 2- | awk '{print $1}')
    if [[ ${SYSPROFILE} == "" ]]; then
        echo "Couldn't determine system profile in tuned" >&2
        exit ${RC_SKIPPED}
    fi

    if [[ ${SYSPROFILE} == "virtual-guest" ]]; then
        exit ${RC_OKAY}
    else
        echo "This system is virtual but profile is not set as virtual-guest, check that it's optimized for usage" >&2
        exit ${RC_INFO}
    fi
fi

exit ${RC_OKAY}
