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

# long_name: Detects if vfs_cache_pressure is over sane defaults
# description: Detects if vfs_cache_pressure is over sane defaults
# priority: 400
# kb: https://access.redhat.com/solutions/16995

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

if [[ "x$RISU_LIVE" == "x0" ]]; then
    FILE="${RISU_ROOT}/sos_commands/kernel/sysctl_-a"
elif [[ "x$RISU_LIVE" == "x1" ]]; then
    FILE=$(mktemp)
    sysctla -a >${FILE}
    trap "rm ${FILE}" EXIT
fi

is_required_file "${FILE}"

VALUE=$(grep vm.vfs_cache_pressure ${FILE} | cut -d "=" -f 2)

if [[ ${VALUE} -ge 1000 ]]; then
    echo $"High vfs_cache_pressure" >&2
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
