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

# long_name: DPDK Configuration
# description: Checks for various DPDK configuration parameters
# priority: 300

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

# Actual code execution
flag=0

# Execute only on OSP nodes
is_required_rpm openstack.*common

if [[ ${CITELLUS_LIVE} -eq 0 ]]; then
    FILE="${CITELLUS_ROOT}/sos_commands/openvswitch/ovs-vsctl_-t_5_get_Open_vSwitch_._other_config"
elif [[ ${CITELLUS_LIVE} -eq 1 ]];then
    FILE=$(mktemp)
    trap "rm ${FILE}" EXIT
    ovs-vsctl -t 5 get Open_vSwitch . other_config > ${FILE}
fi

if [[ -f "$FILE" ]]; then

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

    procids=$(grep ^processor ${CITELLUS_ROOT}/proc/cpuinfo|cut -d ":" -f 2|xargs echo)

    if is_lineinfile "^CPUAffinity.*" "${CITELLUS_ROOT}/etc/systemd/system.conf"; then
        # Check Systemd as alternative:
        # The only step required is hence to configure the CPUAffinity option in /etc/systemd/system.conf.
        # Systemd CPUAffinity should be 'negative' of ISOLCPU's so need to get all CPU's and reverse
        systemdaffinity=$(grep ^CPUAffinity ${CITELLUS_ROOT}/etc/systemd/system.conf|cut -d "=" -f 2)
        systemdaffinity=$(expand_ranges ${systemdaffinity}|sort -V)

        # Loop for getting reversed array (items not in)
        isolated=""
        for i in ${procids[@]}; do
            present=0
            for j in ${systemdaffinity[@]}; do
                if [[ ${i} -eq ${j} ]];then
                    present=1
                fi
            done
            if [[ ${present} -eq 0 ]];then
                isolated="$isolated $i"
            fi
        done
        ISOLCPUS=${isolated}
        USEDBYKERNEL=${systemdaffinity}
    elif is_lineinfile isolcpus ${CITELLUS_ROOT}/proc/cmdline; then
        ISOLCPUS=$(cat ${CITELLUS_ROOT}/proc/cmdline|tr " " "\n"|grep ^isolcpus|cut -d "=" -f 2-|tr ",\'\"" "\n")
        ISOLCPUS=$(expand_ranges ${ISOLCPUS}|sort -V)
        USEDBYKERNEL=""

        echo $"Isolcpus is not the recommended way to do isolation on CPU's please do check tuned and systemd CPUAffinity" >&2

        # Check CPU's not isolated:
        for i in ${procids[@]}; do
            present=1
            for j in ${ISOLCPUS[@]}; do
                if [[ ${i} -eq ${j} ]];then
                    present=0
                fi
            done
            if [[ ${present} -eq 1 ]];then
                USEDBYKERNEL="$USEDBYKERNEL $i"
            fi
        done
    else
        unset ISOLCPUS
    fi

    echo "KERNEL used CPU's: $USEDBYKERNEL" >&2

    FREECPUS=$(echo "$ISOLCPUS"|sort -V)
    echo "CPU's isolated from kernel scheduler $FREECPUS" >&2

    # List of CPU's that other components can use
    VCPUPINSET=$(iniparser "${CITELLUS_ROOT}/etc/nova/nova.conf" DEFAULT vcpu_pin_set|tr ",\'\"" "\n")
    VCPUPINSET=$(expand_and_remove_excludes ${VCPUPINSET})

    echo "CPU's pinned in nova $VCPUPINSET" >&2

    USEDBYNOVA=""
    # Check that NOVA is configured for using CPU's in isolated
    usedcpu=0
    for i in ${VCPUPINSET[@]}; do
        case ${i} in
            ^*)
                # Excluded cpu via nova conf
                ;;
            *)
                present=0
                for j in ${ISOLCPUS[@]}; do
                    if [[ ${i} -eq ${j} ]];then
                        present=1
                        USEDBYNOVA="$USEDBYNOVA $i"
                    fi
                done
                if [[ ${present} -eq 0 ]];then
                    if [[ ${usedcpu} -eq 0 ]]; then
                        echo -n $"Nova VCPU in vcpu_pin_set not in Isolated CPU's:" >&2
                        usedcpu=1
                    fi
                    echo -n " $i" >&2
                    flag=1
                fi
                ;;
        esac
    done

    if [[ ${usedcpu} -eq 1 ]]; then
        echo "" >&2
    fi

    echo "Nova used CPU's (from isolated pool): $USEDBYNOVA" >&2

    # Update the actual list of 'Free' CPU's
    NEWFREE=""
    for i in ${FREECPUS[@]}; do
        present=0
        for j in ${USEDBYNOVA[@]}; do
            if [[ ${i} -eq ${j} ]];then
                present=1
            fi
        done
        if [[ ${present} -eq 0 ]];then
            NEWFREE="$NEWFREE $i"
        fi
    done

    FREECPUS="$NEWFREE"

    echo "-- available CPU's after this step from isolated pool: $FREECPUS" >&2

    # So, first processor (0) is assigned, then 5 unused ones, and next one (6) is enabled, then 5 more unused,
    # then next one is enabled (12), then 5 unused, then one enabled (18), being H the highest processor count
    # and L the lowest (0)

    # The pmd-cpu-mask is 082082, meaning:
    # 1000 0010 0000 1000 0010
    # CPU 1, CPU 7, CPU 13, CPU 19

    DPDKPMDMASK=$(cat ${FILE}|tr " {}," "\n"|grep "^pmd-cpu-mask"|cut -d "=" -f 2|tr -d ",\'\""|tr '[a-z]' '[A-Z]')

    if [[ "${DPDKPMDMASK:0:2}" == "0X" ]] ; then
        # We need to strip 0x
        DPDKPMDMASK=${DPDKPMDMASK:2}
    fi

    BINPMDMASK=$(dc -e "16i2o${DPDKPMDMASK}p"|tr -d '\n\\')

    # Walk the binary PMD mask to find processor numbers
    PMDCPUS=""
    foo="$BINPMDMASK"
    j=0
    for (( i=${#foo}-1; i>=0; i-- )); do
        enabled=0
        enabled="${foo:$i:1}"
        if [[ "$enabled" = "1" ]];then
            PMDCPUS="$PMDCPUS $j"
        fi
        j=$((j+1))
    done

    echo "DPDK PMD used CPU's: $PMDCPUS" >&2


    # Remove from FREE CPU's the ones used by DPDK PMD
    NEWFREE=""
    usedcpu=0
    for i in ${FREECPUS[@]}; do
        present=0
        for j in ${PMDCPUS[@]}; do
            if [[ ${i} -eq ${j} ]];then
                present=1
            fi
        done
        if [[ ${present} -eq 0 ]];then
            # CPU was in free pool
            if [[ ${usedcpu} -eq 0 ]]; then
                echo -n $"DPDK PMD CPU was already used by Nova:" >&2
                usedcpu=1
            fi
            echo -n " $i" >&2
            flag=1
        else
            NEWFREE="$NEWFREE $i"
        fi
    done

    if [[ ${usedcpu} -eq 1 ]]; then
        echo "" >&2
    fi

    FREECPUS="$NEWFREE"
    echo "-- available CPU's after this step from isolated pool: $FREECPUS" >&2


    # cat overcloud-compute-0/sos_commands/openvswitch/ovs-vsctl_-t_5_get_Open_vSwitch_._other_config
    # {dpdk-init="true", dpdk-lcore-mask="41041", dpdk-socket-mem="2048,2048", pmd-cpu-mask="082082"}

    # Mask provided is 00041041 hex, which translates to binary:

    # H rL
    # 1000001000001000001
    # CPU 0, CPU 6, CPU 12, CPU 18

    # We'll be using bc for the conversion:

    DPDKCOREMASK=$(cat ${FILE}|tr " {}," "\n"|grep "^dpdk-lcore-mask"|cut -d "=" -f 2|tr -d ",\'\""|tr '[a-z]' '[A-Z]')

    if [[ "${DPDKCOREMASK:0:2}" == "0X" ]] ; then
        # We need to strip 0x
        DPDKCOREMASK=${DPDKCOREMASK:2}
    fi

    BINCOREMASK=$(dc -e "16i2o${DPDKCOREMASK}p"|tr -d '\n\\')

    # Walk the binary CPU mask to find processor numbers
    CORECPUS=""
    foo="$BINCOREMASK"
    j=0
    for (( i=${#foo}-1; i>=0; i-- )); do
        enabled=0
        enabled="${foo:$i:1}"
        if [[ "$enabled" = "1" ]];then
            CORECPUS="$CORECPUS $j"
        fi
        j=$((j+1))
    done

    echo "DPDK CORE used CPU's: $CORECPUS" >&2

    # Remove from FREE CPU's the ones used by DPDK COREMASK
    USEDCPUS="$(echo ${PMDCPUS} ${USEDBYNOVA} ${USEDBYKERNEL}|tr " " "\n"|sort|uniq|xargs echo)"
    usedcpu=0
    for i in ${USEDCPUS[@]}; do
        present=0
        for j in ${CORECPUS[@]}; do
            if [[ ${i} -eq ${j} ]];then
                present=1
                if [[ ${usedcpu} -eq 0 ]]; then
                    echo -n $"DPDK CORE CPU was already used by Kernel, Nova or DPDK PMD: " >&2
                    usedcpu=1
                fi
                echo -n " $i" >&2
                # NOTE: DPDK CORE CPU's are not mandatory to be isolated, so don't flag
                # flag=1
            fi
        done
    done

    if [[ ${usedcpu} -eq 1 ]]; then
        echo "" >&2
    fi

    USEDCPUS="$(echo ${PMDCPUS} ${USEDBYNOVA} ${USEDBYKERNEL} ${CORECPUS}|tr " " "\n"|sort|uniq|xargs echo)"
    NEWFREE=""
    for i in ${procids[@]}; do
        present=0
        for j in ${USEDCPUS[@]}; do
            if [[ ${i} -eq ${j} ]];then
                present=1
            fi
        done
        if [[ ${present} -eq 0 ]];then
            NEWFREE="$NEWFREE $i"
        fi
    done

    FREECPUS="$NEWFREE"

    if [[ "${#FREECPUS}" != "0" ]];then
        echo "There are CPU's unallocated: $FREECPUS" >&2
        flag=1
    fi
fi

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


if [[ ${flag} -eq '1' ]]; then
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
