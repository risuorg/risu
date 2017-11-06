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
is_required_rpm openstack.*common

# Run this code on controllers, not on computes nor director
if ! is_process nova-compute; then
    if ! is_lineinfile "^scheduler_defaults.*NUMATopologyFilter" "${CITELLUS_ROOT}/etc/nova/nova.conf"; then
        echo $"missing NUMATopologyFilter in nova.conf" >&2
        flag=1
    fi
fi

if [ $CITELLUS_LIVE -eq 0 ]; then
    FILE="${CITELLUS_ROOT}/sos_commands/openvswitch/ovs-vsctl_-t_5_get_Open_vSwitch_._other_config"
elif [ $CITELLUS_LIVE -eq 1 ];then
    FILE=$(mktemp)
    trap "rm $FILE" EXIT
    ovs-vsctl -t 5 get Open_vSwitch . other_config > $FILE
fi

if is_lineinfile "dpdk-init.*true" "${FILE}";then
    # DPDK is supposedly enabled, do further checks

    if ! is_lineinfile "dpdk-socket-mem=" "${FILE}";then
        echo $"missing dpdk-socket-mem in ovs-vsctl" >&2
        flag=1
    fi
    if ! is_lineinfile "dpdk-lcore-mask=" "${FILE}";then
        echo $"missing dpdk-lcore-mask= (Core list) in ovs-vsctl" >&2
        flag=1
    fi
    if ! is_lineinfile "pmd-cpu-mask=" "${FILE}";then
        echo $"missing pmd-cpu-mask= (pmd cpu mask) in ovs-vsctl" >&2
        flag=1
    fi
fi

# TODO(iranzo)
# ./sos_commands/openvswitch/ovs-vsctl_-t_5_show
# type: dpdk

# DPDK: NeutronBridgeMappings: 'dpdk:br-link'
#  NeutronDpdkCoreList: "'4,6,20,22'"
#  NeutronDpdkMemoryChannels: "4"
#  NeutronDpdkDriverType: "vfio-pci"
#  NeutronDatapathType: "netdev"
# HostIsolatedCoreList
# HostCpusList
# NovaReservedHostMemory

# DPDK upstream: https://github.com/openvswitch/ovs/blob/v2.5.0/INSTALL.DPDK.md
# ovs-vswitchd --dpdk
# ifaces with dpdk$NUM


if [[ $flag -eq '1' ]]; then
    exit $RC_FAILED
else
    exit $RC_OKAY
fi
