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

# long_name: Disk inode usage
# description: error if disk inode usage is greater than $CITELLUS_INODE_MAX_PERCENT=90
# priority: 300

: ${CITELLUS_INODE_MAX_PERCENT=90}

if [[ ${CITELLUS_LIVE} = 0 ]]; then
    is_required_file "${CITELLUS_ROOT}/sos_commands/filesys/df_-ali"
    DISK_USE_CMD="cat ${CITELLUS_ROOT}/sos_commands/filesys/df_-ali"
else
    DISK_USE_CMD="df -ali"
fi

#https://unix.stackexchange.com/a/15083
result=$(${DISK_USE_CMD} |awk -vinode_max_percent=${CITELLUS_INODE_MAX_PERCENT} '/^\/dev/ && 0+$5 > inode_max_percent { print $6,$5 }')

if [[ -n "$result" ]]; then
    echo "${result}" >&2
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
