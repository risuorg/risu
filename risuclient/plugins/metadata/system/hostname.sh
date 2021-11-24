#!/bin/bash

# Copyright (C) 2018, 2021 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

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

# long_name: prepares hostname metadata
# description: Sets hostname metadata

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

if [[ ${RISU_LIVE} -eq 0 ]]; then
    FILE="${RISU_ROOT}/hostname"
elif [[ ${RISU_LIVE} -eq 1 ]]; then
    FILE=$(mktemp)
    trap "rm ${FILE}" EXIT
    hostname >${FILE}
fi

is_required_file ${FILE}

# Fill metadata 'hostname' to value
echo "hostname"
cat ${FILE} >&2
exit ${RC_OKAY}
