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

# TODO(iranzo)

# Required packages:
# tuned-profiles-cpu-partitioning.noarch
# /etc/tuned/cpu-partitioning-variables.conf containing isolated_cores=.*
# kernel cmdline isolcpus=$TUNED_CORES"/g'
# NeutronMechanismDrivers: "openvswitch,sriovnicswitch"
# NovaPCI passtru
# NeutronSriovNumVFs
# NovaVcpuPinSet: "8,10,12,14,18,24,26,28,30"
# 'PciPassthroughFilter' in scheduler_defaults
# intel_iommu=on
# intel_iommu=on default_hugepagesz=1GB hugepagesz=1G hugepages=12"

# DPDK: NeutronBridgeMappings: 'dpdk:br-link'
#   NeutronDpdkCoreList: "'4,6,20,22'"
#  NeutronDpdkMemoryChannels: "4"
#  NeutronDpdkDriverType: "vfio-pci"
#  NeutronDatapathType: "netdev"
# NeutronDpdkSocketMemory
# NUMATopologyFilter"
# HostIsolatedCoreList
# HostCpusList
# NovaReservedHostMemory
# iommu=pt

#nova compute
# sriov_agent.ini containing physical_device_mappings =
# neutron-sriov-nic-agent running
#nova scheduler
     # PciPassthroughFilter


# DPDK upstream: https://github.com/openvswitch/ovs/blob/v2.5.0/INSTALL.DPDK.md
# ovs-vswitchd --dpdk
# ifaces with dpdk$NUM


# Load common functions
[ -f "${CITELLUS_BASE}/common-functions.sh" ] && . "${CITELLUS_BASE}/common-functions.sh"

# Actual code execution
RELEASE=$(discover_osp_version)
flag = 0 

if [ "$RELEASE" -gt 7 ];
then
  is_rpm openstack-neutron-sriov-nic-agent || echo "missing rpm openstack-neutron-sriov-nic-agent" >&1
fi

is_lineinfile "${CITELLUS_ROOT}/lspci" "Virtual Function" || echo "virtual function is disabled" >&2
is_lineinfile "${CITELLUS_ROOT}/proc/modules" "vfio_iommu_type1" || echo "vfio_iommu module is not loaded" >&2
is_lineinfile "${CITELLUS_ROOT}/sys/module/vfio_iommu_type1/parameters/allow_unsafe_interrupts" 'Y' || echo "unsafe interrupts not enabled" >&2
is_lineinfile "${CITELLUS_ROOT}/etc/nova/nova.conf" "^pci_passthrough_whitelist" || echo "missing pci_passthrough_whitelist in /etc/nova/nova.conf" >&2

if is_lineinfile "${CITELLUS_ROOT}/proc/cpuinfo" "Intel";
then
  is_lineinfile "${CITELLUS_ROOT}/proc/cmdline" "intel_iommu=on" || echo "missing intel_iommu=on on cmdline" >&2
  is_lineinfile "${CITELLUS_ROOT}/proc/cmdline" "iommu=pt" || echo "missing iommu=pt on cmdline" >&2
else
  is_lineinfile "${CITELLUS_ROOT}/proc/cmdline" "amd_iommu=pt" || echo "missing amd_iommu=pt on cmdline" >&2
fi
