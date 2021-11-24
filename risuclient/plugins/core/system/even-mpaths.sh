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

# we can run this against fs snapshot or live system

# long_name: Checks for an even number of paths
# description: Reports if a multipath device has not an even number of devices
# priority: 800

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

# Code for generating items for faraday-CSV

if [[ ${RISU_LIVE} -eq 0 ]]; then
    FILE="${RISU_ROOT}/sos_commands/multipath/multipath_-l"
elif [[ ${RISU_LIVE} -eq 1 ]]; then
    FILE=$(mktemp)
    trap "rm ${FILE}" EXIT
    multipath -l >${FILE} 2>&1
fi

is_required_file ${FILE}

STATUS=${RC_OKAY}

(
    for lun in $(grep ^36 ${FILE} | awk '{print $1}' | sort); do
        NUMLUNS=$(sed -n '/'^${lun}'.*/,/^360/p' ${FILE} | grep ":" | wc -l)
        if [ $((number % 2)) -neq 0 ]; then
            echo ${lun}:${NUMLUNS} >&2
            STATUS=${RC_FAILED}
        fi

    done
)

exit ${STATUS}
