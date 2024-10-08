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

# we can run this against fs snapshot or live system

# long_name: ABRTd configuration
# description: This plugin check abrtd configuration
# priority: 100

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

is_required_rpm abrt

if ! is_active abrtd; then
    echo $"abrtd is not running on this node" >&2
    exit ${RC_FAILED}
fi

is_required_file "${RISU_ROOT}/proc/sys/kernel/core_pattern"
core_pattern=$(cat "${RISU_ROOT}/proc/sys/kernel/core_pattern")

if [[ $core_pattern == "core" ]]; then
    echo $"core_pattern: core" >&2
    exit ${RC_FAILED}
else
    echo "core_pattern: $core_pattern" >&2
    exit ${RC_OKAY}
fi
