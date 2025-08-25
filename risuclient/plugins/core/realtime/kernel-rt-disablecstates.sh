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

# default_hugepagesz=1GB idle=poll

# intel_pstate=disable rdt=cmt,l3cat,l3cdp,mba iomem=relaxed intel_iommu=on iommu=pt
# skew_tick=1 tsc=reliable
# rcupdate.rcu_normal_after_boot=1
# isolcpus=managed_irq,domain,11-21
# intel_pstate=disable nosoftlockup
# nohz=on nohz_full=11-21 rcu_nocbs=11-21
# irqaffinity=0,1,2,3,4,5,6,7,8,9,10

flag=0

if is_lineinfile "Intel" "${RISU_ROOT}/proc/cpuinfo"; then
    if ! grep -qP "intel.max_cstate=0" ${RISU_ROOT}/proc/cmdline; then
        echo $"missing intel.max_cstate=0 on kernel cmdline" >&2
        flag=1
    fi
    if ! grep -qP "intel_idle.max_cstate=0" ${RISU_ROOT}/proc/cmdline; then
        echo $"missing intel_idle.max_cstate=0 on kernel cmdline" >&2
        flag=1
    fi
fi
if ! grep -qP "processor.max_cstate=0" ${RISU_ROOT}/proc/cmdline; then
    echo $"missing processor.max_cstate=0 on kernel cmdline" >&2
    flag=1
fi
if ! grep -qP "processor_idle.max_cstate=0" ${RISU_ROOT}/proc/cmdline; then
    echo $"missing processor_idle.max_cstate=0 on kernel cmdline" >&2
    flag=1
fi

if [[ ${flag} -eq '1' ]]; then
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
