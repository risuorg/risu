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

# long_name: Memory recommendations
# description: Checks for hypervisor memory vs the recommended values
# priority: 930

# check memory recommendations

is_required_file "${RISU_ROOT}/proc/cpuinfo""${RISU_ROOT}/proc/meminfo"

TOTALCPU=$(cat "${RISU_ROOT}"/proc/cpuinfo | grep "processor" | sort -u | wc -l)
MEMTOTAL=$(cat "${RISU_ROOT}"/proc/meminfo | sed -n -r -e 's/MemTotal:[ \t]+([0-9]+).*/\1/p')
MEMRECOMMEND=$((TOTALCPU * 3000000))
MEMMINIMUM=$((TOTALCPU * 1500000))
if [[ ${MEMTOTAL} -ge 16000000 ]]; then
    echo "memory is greater than 16gb ram"
else
    echo $"memory is lower than 16gb ram" >&2
    exit ${RC_FAILED}
fi
if [[ ${MEMTOTAL} -ge ${MEMMINIMUM} ]]; then
    echo "memory is greater than or equal to recommended minimum (1.5gb per core)"
else
    echo $"memory is lower than (1.5gb per core)" >&2
    exit ${RC_FAILED}
fi
if [[ ${MEMTOTAL} -ge ${MEMRECOMMEND} ]]; then
    echo "memory is greater than or equal to best recommended (3gb per core)"
    exit ${RC_OKAY}
else
    echo $"memory is lower than (3gb per core)" >&2
    exit ${RC_FAILED}
fi
