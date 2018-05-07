#!/bin/bash

# Copyright (C) 2017   Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)

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

# long_name: SR-IOV and DPDK Configuration
# description: Checks for various SRIOV and DPDK configuration parameters
# priority: 300

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

# assume that at least nova.conf should be present or skip
is_required_file "${CITELLUS_ROOT}/etc/nova/nova.conf"

if is_lineinfile "Intel" "${CITELLUS_ROOT}/proc/cpuinfo"; then
    if ! grep -qP "intel_iommu=on|iommu=pt" ${CITELLUS_ROOT}/proc/cmdline; then
        echo $"missing intel_iommu=on or iommu=pt on kernel cmdline" >&2
        flag=1
    fi
else
    if ! is_lineinfile "amd_iommu=pt" "${CITELLUS_ROOT}/proc/cmdline"; then
        echo $"missing amd_iommu=pt on kernel cmdline" >&2
        flag=1
    fi
fi

if [[ -f "${CITELLUS_ROOT}/etc/nova/nova.conf" ]]; then
    VCPUPINSET=$(iniparser "${CITELLUS_ROOT}/etc/nova/nova.conf" DEFAULT vcp_pin_set|tr ",\'\"" "\n")
else
    VCPUPINSET=''
fi

if [[ ! -z ${VCPUPINSET} ]]; then
    if ! is_lineinfile "cpu-partitioning" "${CITELLUS_ROOT}/etc/tuned/active_profile"; then
        echo $"missing tuned-profiles-cpu-partitioning package. cpu-partitioning tuned profile is recommended for SRIOV/DPDK workload" >&2
        flag=1
    fi
fi

if ! is_lineinfile "^enable_isolated_metadata.*rue" "${CITELLUS_ROOT}/etc/neutron/dhcp_agent.ini";then
    echo $"missing Isolated metadata in neutron/dhcp_agent.ini" >&2
    flag=1
fi

if [[ ${flag} -eq '1' ]]; then
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
