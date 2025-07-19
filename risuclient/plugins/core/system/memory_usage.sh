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

# long_name: Memory usage
# description: error if memory usage is higher than $RISU_MEMORY_MAX_PERCENT=90
# priority: 930

: ${RISU_MEMORY_MAX_PERCENT=90}

is_required_file "/usr/bin/bc"

if [[ "x$RISU_LIVE" == "x0" ]]; then
    is_required_file "${RISU_ROOT}/free"
    MEMORY_USE_CMD=$(grep Mem ${RISU_ROOT}/free | sed 's/[ \t]\+/ /g')
elif [[ "x$RISU_LIVE" == "x1" ]]; then
    MEMORY_USE_CMD=$(free | grep Mem | sed 's/[ \t]\+/ /g')
fi

MEMORY_TOTAL=$(echo ${MEMORY_USE_CMD} | cut -d" " -f2)
MEMORY_USED=$(echo ${MEMORY_USE_CMD} | cut -d" " -f3)
MEMORY_USED_PERCENT=$(echo "(($MEMORY_USED / $MEMORY_TOTAL) * 100)" | bc -l)

RC=$(echo "$MEMORY_USED_PERCENT>${RISU_MEMORY_MAX_PERCENT:-90}" | bc -l)

if [[ "x$RC" == "x1" ]]; then
    echo "${MEMORY_USED_PERCENT%%.*}%" >&2
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
