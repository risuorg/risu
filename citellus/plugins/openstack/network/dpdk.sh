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
flag=0

# Execute only on OSP nodes
is_required_rpm openstack-

# Run this code on controllers, not on computes nor director
if ! is_process nova-compute; then
    is_lineinfile "^scheduler_defaults.*NUMATopologyFilter"  "${CITELLUS_ROOT}/etc/nova/nova.conf"|| echo $"missing NUMATopologyFilter in nova.conf" >&2 && flag=1
fi

is_lineinfile "DPDK_OPTIONS.*" "${CITELLUS_ROOT}/etc/sysconfig/openvswitch" || echo "missing DPDK_OPTIONS in /etc/sysconfig/openvswitch" >&2 && flag=1
is_lineinfile "DPDK_OPTIONS.*socket-mem.*" "${CITELLUS_ROOT}/etc/sysconfig/openvswitch" || echo $"missing socket-mem in DPDK_OPTIONS in /etc/sysconfig/openvswitch" >&2 && flag=1
is_lineinfile "DPDK_OPTIONS.*-l [0-9].*" "${CITELLUS_ROOT}/etc/sysconfig/openvswitch"  || echo $"missing -l (Core list) in DPDK_OPTIONS in /etc/sysconfig/openvswitch" >&2 && flag=1
is_lineinfile "DPDK_OPTIONS.*-n [0-9].*" "${CITELLUS_ROOT}/etc/sysconfig/openvswitch" || echo $"missing -n (Memory channels) in DPDK_OPTIONS in /etc/sysconfig/openvswitch" >&2 && flag=1



# TODO(iranzo)
# ./sos_commands/openvswitch/ovs-vsctl_-t_5_show
# type: dpdk

# [piranzo@]$ cat ./sos_commands/openvswitch/ovs-vsctl_-t_5_get_Open_vSwitch_._other_config 
# {dpdk-init="true", dpdk-lcore-mask="f0000000000f", dpdk-socket-mem="2048,2048", pmd-cpu-mask="fc000300000fc00030"}



# DPDK: NeutronBridgeMappings: 'dpdk:br-link'
#  NeutronDpdkCoreList: "'4,6,20,22'"
#  NeutronDpdkMemoryChannels: "4"
#  NeutronDpdkDriverType: "vfio-pci"
#  NeutronDatapathType: "netdev"
# HostIsolatedCoreList
# HostCpusList
# NovaReservedHostMemory

# $ cat etc/sysconfig/openvswitch
# DPDK_OPTIONS = "-l 12,40,13,41 -n 4 --socket-mem 40964096 -w 0000:05:00.0 -w 0000:08:00.0"
# DPDK upstream: https://github.com/openvswitch/ovs/blob/v2.5.0/INSTALL.DPDK.md
# ovs-vswitchd --dpdk
# ifaces with dpdk$NUM


if [[ $flag -eq '1' ]]; then
    exit $RC_FAILED
else
    exit $RC_OKAY
fi
