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

# long_name: Max CPU speed and C-states
# description: Checks for CPU speed and C-states
# priority: 920

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

# check baremetal node

is_required_file "${RISU_ROOT}/sys/module/intel_idle/parameters/max_cstate" \
    "${RISU_ROOT}/proc/cpuinfo"

cstate=$(cat "${RISU_ROOT}/sys/module/intel_idle/parameters/max_cstate")

if [[ ${cstate} -ne "0" ]]; then
    echo $"CPU is not running at full speed. Please refer https://access.redhat.com/solutions/202743 " >&2
    grep -E "processor|cpu MHz" "${RISU_ROOT}/proc/cpuinfo" | tr '\n' ' ' | sed 's/processor/\nprocessor/g' >&2
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
