#!/bin/bash

# Copyright (C) 2018   Robin Černín (rcernin@redhat.com)

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

# long_name: Process High CPU usage
# description: error if process cpu usage is greater than $CITELLUS_PROCESS_CPU_USAGE=100
# priority: 800

: ${CITELLUS_PROCESS_CPU_USAGE=100}

if [[ ${CITELLUS_LIVE} = 0 ]]; then
    is_required_file "${CITELLUS_ROOT}/ps"
    FILE="${CITELLUS_ROOT}/ps"
else
    FILE=$(mktemp)
    trap "rm ${FILE}" EXIT
    ps aux > ${FILE}
fi

header=$(head -1 ${FILE})
result=$(awk -vcpu_high_usage=${CITELLUS_PROCESS_CPU_USAGE} '$3>cpu_high_usage { print $0 }' ${FILE})

if [[ -n "$result" ]]; then
    echo "${header}" >&2
    echo "${result}" >&2
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
