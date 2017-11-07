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
    if ! is_lineinfile "^scheduler_defaults.*NUMATopologyFilter" "${CITELLUS_ROOT}/etc/nova/nova.conf"; then
        echo $"missing NUMATopologyFilter in nova.conf" >&2
        flag=1
    fi
fi

if ! is_lineinfile "DPDK_OPTIONS.*" "${CITELLUS_ROOT}/etc/sysconfig/openvswitch";then
    echo "missing DPDK_OPTIONS in /etc/sysconfig/openvswitch" >&2
    flag=1
fi
if ! is_lineinfile "DPDK_OPTIONS.*socket-mem.*" "${CITELLUS_ROOT}/etc/sysconfig/openvswitch";then
    echo $"missing socket-mem in DPDK_OPTIONS in /etc/sysconfig/openvswitch" >&2
    flag=1
fi
if ! is_lineinfile "DPDK_OPTIONS.*-l [0-9].*" "${CITELLUS_ROOT}/etc/sysconfig/openvswitch";then
    echo $"missing -l (Core list) in DPDK_OPTIONS in /etc/sysconfig/openvswitch" >&2
    flag=1
fi
if ! is_lineinfile "DPDK_OPTIONS.*-n [0-9].*" "${CITELLUS_ROOT}/etc/sysconfig/openvswitch";then
    echo $"missing -n (Memory channels) in DPDK_OPTIONS in /etc/sysconfig/openvswitch" >&2
    flag=1
fi



# Check Systemd as alternative:
# The only step required is hence to configure the CPUAffinity option in /etc/systemd/system.conf.

# For example:

# NUMA node0 CPU(s): 0-5,12-17
# NUMA node1 CPU(s): 6-11,18-23

# [root@overcloud-compute-0 ~]# cat /proc/cmdline
# isolcpus=1,2,3,4,5,7,8,9,10,11,13,14,15,16,17,19,20,21,22,23 nohz=on nohz_full=1,2,3,4,5,7,8,9,10,11,13,14,15,16,17,19,20,21,22,23 rcu_nocbs=1,2,3,4,5,7,8,9,10,11,13,14,15,16,17,19,20,21,22,23 tuned.non_isolcpus=00041041 intel_pstate=disable nosoftlockup

# [overcloud-compute-0]$ grep vcpu_pin_set etc/nova/nova.conf
# vcpu_pin_set=2,3,4,5,8,9,10,11,14,15,16,17,20,21,22,23

# cat overcloud-compute-0/sos_commands/openvswitch/ovs-vsctl_-t_5_get_Open_vSwitch_._other_config
# {dpdk-init="true", dpdk-lcore-mask="41041", dpdk-socket-mem="2048,2048", pmd-cpu-mask="082082"}

# Mask provided is 00041041 hex, which translates to binary:

# H L
# 1000001000001000001

# So, first processor (0) is assigned, then 5 unused ones, and next one (6) is enabled, then 5 more unused, then next one is enabled (12), then 5 unused, then one enabled (18), being H the highest processor count and L the lowest (0), so this is coherent with the isolcpus list

# The pmd-cpu-mask is 082082, meaning:
# 1000 0010 0000 1000 0010

# CPU 1, CPU 7, CPU 13, CPU 19


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
