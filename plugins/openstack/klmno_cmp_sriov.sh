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

# Checking PCI PASS TRU for SRIOV
# Ref: None
# Based on
# https://access.redhat.com/documentation/en-us/red_hat_openstack_platform/11/html-single/network_functions_virtualization_configuration_guide/
# https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/7/html/Virtualization_Deployment_and_Administration_Guide/sect-SR_IOV-Troubleshooting_SR_IOV.html

REFNAME="SRIOV"
REFOSP_VERSION="kilo liberty mitaka newton ocata"
REFNODE_TYPE="compute controller"



# Looks for VF enabled
grep_file "${DIRECTORY}/lspci" "Virtual Function"

# Looks for VFIO_IOMMU enabled
grep_file "${DIRECTORY}/proc/modules" "vfio_iommu_type1"

# Unsafe interrupts enabled (for HOTPLUG)
grep_file "${DIRECTORY}/sys/module/vfio_iommu_type1/parameters/allow_unsafe_interrupts" "Y"

# Are we Intel or AMD?
grep -iq intel "${DIRECTORY}/proc/cpuinfo"
INTEL=$?
if [ "#$INTEL" == "#0" ];
then
    # Check for IOMMU (VT-d) (INTEL)
    grep_file "${DIRECTORY}/proc/cmdline" "intel_iommu=on"
    grep_file "${DIRECTORY}/proc/cmdline" "iommu=pt"
else
    # Check for AMD
    grep_file "${DIRECTORY}/cmdline" "amd_iommu=pt"
fi

# Looks for the pci_pass_tru in Nova
grep_file "${DIRECTORY}/etc/nova/nova.conf" "pci_passthrough_whitelist = "

