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

# long_name: SR-IOV Configuration
# description: Checks for various SRIOV configuration parameters
# priority: 300

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

# assume that at least nova.conf should be present or skip
is_required_file "${CITELLUS_ROOT}/etc/nova/nova.conf"

# Actual code execution
RELEASE=$(discover_osp_version)

flag=0

if [[ "$RELEASE" -gt 7 ]]; then
    if ! is_rpm openstack-neutron-sriov-nic-agent > /dev/null 2>&1;then
        echo $"missing rpm openstack-neutron-sriov-nic-agent" >&2
        flag=1
    fi
    if ! is_process neutron-sriov-nic-agent;then
        echo $"neutron-sriov-nic-agent not running" >&2
        flag=1
    fi
fi

if [[ "x$CITELLUS_LIVE" = "x1" ]];  then
    if [[ "$(lspci|grep "Virtual Function"|wc -l)" -eq "0" ]]; then
        vfflag=1
        flag=1
    fi
elif [[ "x$CITELLUS_LIVE" = "x0" ]]; then
    if ! is_lineinfile "Virtual Function" "${CITELLUS_ROOT}/lspci";then
        vfflag=1
        flag=1
    fi
fi

if [[ "x$vfflag" = "x1" ]]; then
    echo $"virtual function is disabled" >&2
fi

if ! is_lineinfile "vfio_iommu_type1" "${CITELLUS_ROOT}/proc/modules"; then
    echo $"vfio_iommu module is not loaded" >&2
    flag=1
fi

if ! is_lineinfile 'Y' "${CITELLUS_ROOT}/sys/module/vfio_iommu_type1/parameters/allow_unsafe_interrupts";then
    echo $"unsafe interrupts not enabled" >&2
    flag=1
fi

if ! is_lineinfile "hugepagesz=" "${CITELLUS_ROOT}/proc/cmdline";then
    echo $"missing hugepagesz on kernel cmdline" >&2
    flag=1
fi

if ! is_lineinfile "hugepages=" "${CITELLUS_ROOT}/proc/cmdline";then
    echo $"missing hugepages= on kernel cmdline" >&2
    flag=1
fi

if ! is_lineinfile "mechanism_drivers.*sriovnicswitch" "${CITELLUS_ROOT}/etc/neutron/plugins/ml2/ml2_conf.ini";then
    echo $"missing sriovnicswitch in ml2_conf.ini" >&2
    flag=1
fi


if [[ "$(discover_osp_version)" -lt "11" ]]; then
    if ! is_lineinfile "^scheduler_defaults.*PciPassthroughFilter" "${CITELLUS_ROOT}/etc/nova/nova.conf";then
        missingpcipasstru=1
        flag=1
    fi
else
    # Ocata and higher
    if ! is_lineinfile "^enabled_filters.*PciPassthroughFilter" "${CITELLUS_ROOT}/etc/nova/nova.conf";then
        missingpcipasstru=1
        flag=1
    fi
fi

if [[ "$missingpcipasstru" -eq "1" ]]; then
    echo $"missing PciPassthroughFilter in nova.conf" >&2
fi

if ! is_lineinfile "^pci_passthrough_whitelist" "${CITELLUS_ROOT}/etc/nova/nova.conf";then
    echo $"missing pci_passthrough_whitelist in /etc/nova/nova.conf" >&2
    flag=1
fi

if is_process nova-compute; then
    if ! is_lineinfile "^physical_device_mappings.*" "${CITELLUS_ROOT}/etc/neutron/plugins/ml2/sriov_agent.ini";then
        echo $"missing physical_device_mappings in /etc/neutron/plugins/ml2/sriov_agent.ini" >&2
        flag=1
    fi
fi
# NeutronSriovNumVFs

if [[ ${flag} -eq '1' ]]; then
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
