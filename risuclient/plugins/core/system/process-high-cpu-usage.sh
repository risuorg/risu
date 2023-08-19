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

# long_name: Process High CPU usage
# description: error if process cpu usage is greater than $RISU_PROCESS_CPU_USAGE=100
# priority: 800

: ${RISU_PROCESS_CPU_USAGE=100}

if [[ ${RISU_LIVE} == 0 ]]; then
    is_required_file "${RISU_ROOT}/ps"
    FILE="${RISU_ROOT}/ps"
else
    FILE=$(mktemp)
    trap "rm ${FILE}" EXIT
    ps aux >${FILE}
fi

header=$(head -1 ${FILE})
result=$(awk -vcpu_high_usage=${RISU_PROCESS_CPU_USAGE} '$3>cpu_high_usage { print $0 }' ${FILE})

if [[ -n $result ]]; then
    echo "${header}" >&2
    echo "${result}" >&2
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
