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

# Version function cloned from version.sh

discover_version(){
case ${VERSION} in
  openstack-nova-common-2014.*) echo 6 ;;
  openstack-nova-common-2015.*) echo 7 ;;
  openstack-nova-common-12.*) echo 8 ;;
  openstack-nova-common-13.*) echo 9 ;;
  openstack-nova-common-14.*) echo 10 ;;
  openstack-nova-common-15.*) echo 11 ;;
  openstack-nova-common-16.*) echo 12 ;;
  *) echo 0 ;;
esac
}

checksettings(){
  # Looks for VF enabled
  if ! grep -q "Virtual Function" "${CITELLUS_ROOT}/lspci"; then
    echo "virtual function is disabled" >&2
    flag=1
  fi
  # Looks for VFIO_IOMMU enabled
  if ! grep -q "vfio_iommu_type1" "${CITELLUS_ROOT}/proc/modules"; then
    echo "vfio_iommu module is not loaded" >&2
    flag=1
  fi
  # Unsafe interrupts enabled (for HOTPLUG)
  if [ -e "${CITELLUS_ROOT}/sys/module/vfio_iommu_type1/parameters/allow_unsafe_interrupts" ]; then
    if ! grep -q "Y" "${CITELLUS_ROOT}/sys/module/vfio_iommu_type1/parameters/allow_unsafe_interrupts"; then
    echo "unsafe interrupts not enabled" >&2
    flag=1
    fi
  else
    echo "missing allow_unsafe_interrupts file - skipped" >&2
  fi
  # Are we Intel or AMD?
  grep -iq intel "${CITELLUS_ROOT}/proc/cpuinfo"
  INTEL=$?
  if [ "#$INTEL" = "#0" ];
  then
    # Check for IOMMU (VT-d) (INTEL)
    if ! grep -q "intel_iommu=on" "${CITELLUS_ROOT}/proc/cmdline"; then
      echo "missing intel_iommu=on on cmdline" >&2
      flag=1
    fi
    if ! grep -q "iommu=pt" "${CITELLUS_ROOT}/proc/cmdline"; then
      echo "missing iommu=pt on cmdline" >&2
    fi
  else
    # Check for AMD
    if ! grep -q "amd_iommu=pt" "${CITELLUS_ROOT}/cmdline"; then
      echo "missing amd_iommu=pt on cmdline" >&2
    fi
    # Are we Intel or AMD?
    grep -iq intel "${CITELLUS_ROOT}/proc/cpuinfo"
    INTEL=$?
    if [ "#$INTEL" = "#0" ];
    then
	# Check for IOMMU (VT-d) (INTEL)
	if ! grep -q "intel_iommu=on" "${CITELLUS_ROOT}/proc/cmdline"; then
	  echo "missing intel_iommu=on on cmdline" >&2
	  flag=1
	fi
	if ! grep -q "iommu=pt" "${CITELLUS_ROOT}/proc/cmdline"; then
	  echo "missing iommu=pt on cmdline" >&2
	fi
    else
	# Check for AMD
	if ! grep -q "amd_iommu=pt" "${CITELLUS_ROOT}/cmdline"; then
	  echo "missing amd_iommu=pt on cmdline" >&2
	fi
    fi
  # Looks for the pci_pass_tru in Nova
  if [ -e "${CITELLUS_ROOT}/etc/nova/nova.conf" ]; then
    if ! egrep -q "^pci_passthrough_whitelist" "${CITELLUS_ROOT}/etc/nova/nova.conf"; then
      echo "missing pci_passthrough_whitelist in /etc/nova/nova.conf" >&2
    fi
  else
    echo "missing /etc/nova/nova.conf - skipped" >&2
  fi
}

if [ "x$CITELLUS_LIVE" = "x0" ];  then
  # Check which version we are using
  if [ -f ${CITELLUS_ROOT}/installed-rpms ];
  then
    VERSION=$(grep "openstack-nova-common" "${CITELLUS_ROOT}/installed-rpms")
    RELEASE=$(discover_version)

    if [ "$RELEASE" -gt 7 ];
    then
      if grep -q "openstack-neutron-sriov-nic-agent" "${CITELLUS_ROOT}/installed-rpms"
      then

        checksettings
      else
        echo "openstack-neutron-sriov-nic-agent package missing" >&2
        exit $RC_SKIPPED
      fi
    else
      # FOR releases up-to-7 we don't need the service, so check it always
      checksettings
    fi
  else
    echo "missing required file /installed-rpms" >&2
    exit $RC_SKIPPED
  fi
elif [ "x$CITELLUS_LIVE" = "x1" ];  then
  # Check which version we are using
  VERSION=$(rpm -qa | grep "openstack-nova-common")
  RELEASE=$(discover_version)

  if [ "$RELEASE" -gt 7 ];
  then
    rpm -q "openstack-neutron-sriov-nic-agent"  >/dev/null 2>&1
    installed=$?
    if [ "x$installed" = "x0"]
    then
      checksettings
    else
      echo "openstack-neutron-sriov-nic-agent package missing" >&2
      exit $RC_SKIPPED
    fi
  else
    # FOR releases up-to-7 we don't need the service, so check it always
    checksettings
  fi
fi
