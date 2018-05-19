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

# long_name: Hardware Virtualization support
# description: Checks for HW virtualization support
# priority: 200

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

# check baremetal node

is_required_file "${CITELLUS_ROOT}/proc/cpuinfo"
if ! is_enabled libvirtd ; then
    echo $"skipping check for HW virtualization support as libvirtd is not enabled" >&2
    exit ${RC_SKIPPED}
fi

if ! is_lineinfile "svm|vmx" "${CITELLUS_ROOT}/proc/cpuinfo"; then
    echo $"no hardware virt support found in /proc/cpuinfo" >&2
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
