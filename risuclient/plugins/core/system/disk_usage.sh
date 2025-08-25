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

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

# long_name: Disk space usage
# description: error if disk usage is greater than $RISU_DISK_MAX_PERCENT=75
# priority: 400

: ${RISU_DISK_MAX_PERCENT=75}

if [[ ${RISU_LIVE} == 0 ]]; then
    is_required_file "${RISU_ROOT}/df"
    DISK_USE_CMD="cat ${RISU_ROOT}/df"
else
    DISK_USE_CMD="df -P"
fi

#https://unix.stackexchange.com/a/15083
result=$(${DISK_USE_CMD} | awk -vdisk_max_percent=${RISU_DISK_MAX_PERCENT} '/^\/dev/ && 0+$5 > disk_max_percent { print $6,$5 }')

if [[ -n $result ]]; then
    echo "${result}" >&2
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
