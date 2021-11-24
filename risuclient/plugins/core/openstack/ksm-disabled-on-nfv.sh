#!/bin/bash
# Copyright (C) 2018, 2020, 2021 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# long_name: Checks for KSM enabled on NFV deployment
# description: Checks for KSM enabled on NFV deployment
# priority: 500
# kb: https://access.redhat.com/articles/3250261

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

# check if we are running against compute
if ! is_process nova-compute; then
    echo $"Not running on OSP compute host" >&2
    exit ${RC_SKIPPED}
fi

flag=0

if is_lineinfile "hugepages" "${RISU_ROOT}/proc/cmdline"; then
    # DPDK is supposedly enabled, do further checks
    if is_enabled ksmtuned; then
        flag=1
    fi
    if is_active ksmtuned; then
        flag=1
    fi
    if is_lineinfile "0" "${RISU_ROOT}/sys/kernel/mm/ksm/run"; then
        flag=1
    fi
fi

if [[ ${flag} == "1" ]]; then
    echo $"KSM could affect performance when using Hugepages (NFV), please disable it" >&2
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
