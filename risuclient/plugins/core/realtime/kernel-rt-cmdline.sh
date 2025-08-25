#!/bin/bash

# Copyright (C) 2025 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

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

# long_name: Check isolcpus defined
# description: This plugin check isolcpus defined configuration
# priority: 910

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

flag=0

if is_lineinfile "Intel" "${RISU_ROOT}/proc/cpuinfo"; then
    if ! grep -qP "intel_iommu=on|iommu=pt" ${RISU_ROOT}/proc/cmdline; then
        echo $"missing intel_iommu=on or iommu=pt on kernel cmdline" >&2
        flag=1
    fi
else
    if ! is_lineinfile "amd_iommu=pt" "${RISU_ROOT}/proc/cmdline"; then
        echo $"missing amd_iommu=pt on kernel cmdline" >&2
        flag=1
    fi
fi

if ! grep -qP "isolcpus=" ${RISU_ROOT}/proc/cmdline; then
    echo $"missing solcpus on kernel cmdline" >&2
    flag=1
fi

if [[ ${flag} -eq '1' ]]; then
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
