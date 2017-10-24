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

# Load common functions
[ -f "${CITELLUS_BASE}/common-functions.sh" ] && . "${CITELLUS_BASE}/common-functions.sh"

# Actual code execution
RELEASE=$(discover_osp_version)

flag=0

if [ "$RELEASE" -gt 7 ]; then
    is_rpm openstack-neutron-sriov-nic-agent || echo "missing rpm openstack-neutron-sriov-nic-agent" >&2 && flag=1
    is_process neutron-sriov-nic-agent || echo "neutron-sriouv-nic-agent not running" >&1 && flag=1
fi

is_rpm tuned-profiles-cpu-partitioning || echo "missing rpm tuned-profiles-cpu-partitioning" >&2 && flag=1
is_lineinfile "^isolated_cores=.*" "${CITELLUS_ROOT}/etc/tuned/cpu-partitioning-variables.conf" || echo "missing isolated_cores in /etc/tuned/cpu-partitioning-variables.conf" >&2  && flag=1

if [ "x$CITELLUS_LIVE" = "x1" ];  then
    if [ "$(lspci|grep Virtual Function|wc -l)" -eq "0" ]; then
        echo "virtual function is disabled" >&2 && flag=1
    fi
elif [ "x$CITELLUS_LIVE" = "x0" ]; then
    is_lineinfile "Virtual Function" "${CITELLUS_ROOT}/lspci" || echo "virtual function is disabled" >&2 && flag=1
fi

is_lineinfile "vfio_iommu_type1" "${CITELLUS_ROOT}/proc/modules" || echo "vfio_iommu module is not loaded" >&2 && flag=1
is_lineinfile 'Y' "${CITELLUS_ROOT}/sys/module/vfio_iommu_type1/parameters/allow_unsafe_interrupts" || echo "unsafe interrupts not enabled" >&2 && flag=1

if is_lineinfile "Intel" "${CITELLUS_ROOT}/proc/cpuinfo"; then
    is_lineinfile "intel_iommu=on" "${CITELLUS_ROOT}/proc/cmdline" || echo "missing intel_iommu=on on kernel cmdline" >&2  && flag=1
    is_lineinfile "iommu=pt" "${CITELLUS_ROOT}/proc/cmdline" || echo "missing iommu=pt on kernel cmdline" >&2  && flag=1
else
    is_lineinfile "amd_iommu=pt" "${CITELLUS_ROOT}/proc/cmdline" || echo "missing amd_iommu=pt on kernel cmdline" >&2  && flag=1
fi

is_lineinfile "hugepagesz=" "${CITELLUS_ROOT}/proc/cmdline" || echo "missing hugepagesz on kernel cmdline" >&2  && flag=1
is_lineinfile "hugepages=" "${CITELLUS_ROOT}/proc/cmdline" || echo "missing hugepages= on kernel cmdline" >&2  && flag=1
is_lineinfile "isolcpus=" "${CITELLUS_ROOT}/proc/cmdline" || echo "missing isolcpus= on kernel cmdline" >&2  && flag=1

is_lineinfile "mechanism_drivers.*sriovnicswitch" "${CITELLUS_ROOT}/etc/neutron/plugins/ml2/ml2_conf.ini" || echo "missing sriovnicswitch in ml2_conf.ini" >&2  && flag=1

is_lineinfile "^scheduler_defaults.*PciPassthroughtFilter" "${CITELLUS_ROOT}/etc/nova/nova.conf" || echo "missing PciPassthroughFilter in nova.conf" >&2 && flag=1
is_lineinfile "^vcpu_pin_set.*" "${CITELLUS_ROOT}/etc/nova/nova.conf" || echo "missing vcpu_pin_set in nova.conf" >&2 && flag=1
is_lineinfile "^pci_passthrough_whitelist" "${CITELLUS_ROOT}/etc/nova/nova.conf" || echo "missing pci_passthrough_whitelist in /etc/nova/nova.conf" >&2 && flag=1

if is_process nova-compute; then
    is_lineinfile "^physical_device_mappings.*" "${CITELLUS_ROOT}/etc/neutron/plugins/ml2/sriov_agent.ini" || echo "missing physical_device_mappings in /etc/neutron/plugins/ml2/sriov_agent.ini" >&2 && flag=1
fi
# NeutronSriovNumVFs

if [[ $flag -eq '1' ]]; then
    exit $RC_FAILED
else
    exit $RC_OKAY
fi
