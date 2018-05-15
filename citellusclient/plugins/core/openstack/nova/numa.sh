#!/bin/bash

# Copyright (C) 2018   Jaison Raju (jraju@redhat.com)

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

# long_name: NUMA Configuration on Compute nodes
# description: Checks for CPU tuning on compute nodes are as per best practices
# priority: 300

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

# Actual code execution
flag=0

is_required_file "${CITELLUS_ROOT}/etc/nova/nova.conf"
# Run this code on controllers, not on computes nor director
if ! is_process nova-compute; then
    if ! is_lineinfile "^scheduler_defaults.*NUMATopologyFilter" "${CITELLUS_ROOT}/etc/nova/nova.conf"; then
        echo $"missing NUMATopologyFilter in nova.conf" >&2
        flag=1
    fi
else
# Run this script only on compute nodes.
    if is_lineinfile isolcpus ${CITELLUS_ROOT}/proc/cmdline; then
            ISOLCPUS=$(cat ${CITELLUS_ROOT}/proc/cmdline|tr " " "\n"|grep ^isolcpus|cut -d "=" -f 2-|tr ",\'\"" "\n")
            ISOLCPUS=$(expand_ranges ${ISOLCPUS}|sort -V)
    else
            ISOLCPUS=''
    fi
    if ! is_lineinfile "^vcpu_pin_set.*" "${CITELLUS_ROOT}/etc/nova/nova.conf";then
        echo $"missing vcpu_pin_set in nova.conf" >&2
        VCPUPINSET=''
        flag=1
    else
        VCPUPINSET=$(iniparser "${CITELLUS_ROOT}/etc/nova/nova.conf" DEFAULT vcpu_pin_set|tr ",\'\"" "\n")
        VCPUPINSET=$(expand_and_remove_excludes ${VCPUPINSET})
    fi


# We are depending on any instance's libvirt xml to be present in sosreport to identify if the computes have instances which use cpu_policy dedicated.
    pinned=''
    unpinned=''

    for libvirt_xml in `find ${CITELLUS_ROOT}/etc/ -type f -name "instance-*.xml"`; do
        if $(grep -q vcpupin ${libvirt_xml} ); then
            pinned="$(xmllint --xpath "string(//name)" ${libvirt_xml} ) "${pinned}
        elif ! $(grep -q vcpupin $libvirt_xml); then
            unpinned="$(xmllint --xpath "string(//name)" ${libvirt_xml} ) "${unpinned}
        fi
    done

    if [ ! -z "${pinned}" -a ! -z "${unpinned}" ]; then
        echo -ne "computes have both type instances using pinned & unpinned cores. It should not. We need to use host aggregates to separate cpu dedicated & non dedicated workloads.\n Refer KCS: https://access.redhat.com/solutions/3422081" >&2
        flag=1
    elif [[ ! -z "${unpinned}" ]]; then
        if [[ ! -z "${ISOLCPUS}" ]]; then
            misconfigured_cores=''
            for i in ${VCPUPINSET}; do
                if $(egrep -q " $i |^$i | $i$" ${ISOLCPUS} ) ; then
                misconfigured_cores=${misconfigured_cores}" ${i}"
                fi
            done
            if [[ ! -z "${misconfigured_cores}" ]]; then
                echo -ne "Compute is hosting instances without cpu_policy, hence it should not isolated cores used by nova (vcpu_pin_set) in kernel using isolcpus. Although these cores can be tuned using cpu-partitioning profile.\nvcpu_pin_set cores ${misconfigured_cores} are isolated in kernel via isolcpus core: ${ISOLCPUS}" >&2
                flag=1
            fi
        fi

    elif [[ ! -z ${pinned} ]]; then
        if ! is_rpm tuned-profiles-cpu-partitioning > /dev/null 2>&1;then
            echo $"missing rpm tuned-profiles-cpu-partitioning" >&2
            flag=1
        fi

        if [[ ! -z ${VCPUPINSET} ]]; then
            if ! is_lineinfile "cpu-partitioning" "${CITELLUS_ROOT}/etc/tuned/active_profile"; then
                echo $"missing tuned-profiles-cpu-partitioning package. cpu-partitioning tuned profile is recommended for CPU pinned instances" >&2
                flag=1
            fi
        fi

        if ! is_lineinfile "^isolated_cores=.*" "${CITELLUS_ROOT}/etc/tuned/cpu-partitioning-variables.conf";then
            echo $"missing isolated_cores in /etc/tuned/cpu-partitioning-variables.conf" >&2
            flag=1
        else
            TUNED_CORES=$(grep "^isolated_cores=.*" "${CITELLUS_ROOT}/etc/tuned/cpu-partitioning-variables.conf" |cut -f2 -d\= |tr ",\'\"" "\n")
            TUNED_CORES=$(expand_and_remove_excludes ${TUNED_CORES})

            #check if vcpu_pin_set cores are tuned & tuned profile is set
            misconfigured_cores=''
            for i in ${VCPUPINSET}; do
                if ! $( echo ${TUNED_CORES} | egrep -q " $i |^$i | $i$" ) ; then
                    misconfigured_cores=${misconfigured_cores}" ${i}"
                fi
            done
            if [[ ! -z ${misconfigured_cores} ]]; then
                echo -ne "Compute is hosting instances with cpu_policy, hence it should tune cpu cores used by nova (vcpu_pin_set) using tuned profile 'cpu-partitioning'.\nError: vcpu_pin_set cores ${misconfigured_cores} are not tuned  by tuned profile in ${TUNED_CORES}. \nCPU cores used by instances with dedicated cpu_policy should be tuned for better performance " >&2
                flag=1
            fi
        fi

    # check if vcpu cores are isolated
        if [[ ! -z "${ISOLCPUS}" ]]; then
            misconfigured_cores=''
            for i in ${VCPUPINSET}; do
                if ! $( echo ${TUNED_CORES} | egrep -q " $i |^$i | $i$" ) ; then
                    misconfigured_cores=${misconfigured_cores}" ${i}"
                fi
            done
            if [[ ! -z ${misconfigured_cores} ]]; then
                echo -ne "Compute is hosting instances with cpu_policy, hence it should isolated cores used by nova (vcpu_pin_set) in kernel using isolcpus. \nvcpu_pin_set cores ${misconfigured_cores} are not isolated in kernel via isolcpus ${ISOLCPUS}.\nCPU cores used by instances with dedicated cpu_policy should be isolated using isolcpus in kernel for better performance https://access.redhat.com/solutions/2884991\n" >&2
                flag=1
            fi
        fi

        numa_nodes=$(cat ${CITELLUS_ROOT}/sos_commands/processor/lscpu | grep "NUMA node(s)"| awk -F':[[:space:]]*' '{print $2}')

        # Identify if HT enabled
        if [[ $( cat ${CITELLUS_ROOT}/sos_commands/processor/lscpu | grep ^Thread | awk -F':[[:space:]]*' '{print $2}') = "2" ]]; then
        # First get all the siblings.
            cores_per_socket=$( cat ${CITELLUS_ROOT}/sos_commands/processor/lscpu | grep "Core(s) per socket"| awk -F':[[:space:]]*' '{print $2}')
            for i in `seq 0 $(expr ${numa_nodes} - 1)` ; do
                NUMA_CORES[$i]=$( cat ${CITELLUS_ROOT}/sos_commands/processor/lscpu | grep "NUMA node$i CPU"| awk -F':[[:space:]]*' '{print $2}')
                if [[ "$NUMA_CORES[$i]" == *"-"* ]]; then
                    eval "sibling${i}0=( $(echo ${NUMA_CORES[${i}]}|awk -F "," '{print $1}'| awk -F "-" '{print $1" "$2}'|xargs seq ) )"
                    eval "sibling${i}1=( $(echo ${NUMA_CORES[${i}]}|awk -F "," '{print $2}'| awk -F "-" '{print $1" "$2}'|xargs seq ) )"
                fi
            done
        fi


        # if HT enabled, check all instances uses cores & its sibling threads
        for libvirt_xml in `ls ${CITELLUS_ROOT}/etc/libvirt/qemu/instance-*.xml`; do
            instance_cpus=$(echo 'cat //cputune/vcpupin/@cpuset' | xmllint --shell ${libvirt_xml} | awk -F\" 'NR % 2 == 0 { print $2 }')
            for i in ${instance_cpus}; do
                for j in `seq 0 $(expr ${numa_nodes} - 1)` ; do
                    for k in `seq 0 $(expr ${cores_per_socket} - 1)`; do
                        if [[ $i = $sibling${j}0[$k] ]]; then
                            if [[ ! $(echo ${instance_cpus} |egrep  -o " $sibling${j}1[$k] |^$sibling${j}1[$k] | $sibling${j}1[$k]$" | wc -l ) = '1' ]]; then
                                echo "Sibling core of $i of $(xmllint --xpath "string(//name)" ${libvirt_xml} ) : $sibling${j}1[$k] is not being used" >&2
                                flag=1
                            fi
                        fi
                        if [[ $i = $sibling${j}1[$k] ]]; then
                            if [[ ! $(echo ${instance_cpus} |egrep  -o " $sibling${j}0[$k] |^$sibling${j}0[$k] | $sibling${j}0[$k]$" | wc -l ) = '1' ]]; then
                                echo "Sibling core of $i of $(xmllint --xpath "string(//name)" ${libvirt_xml} ) : $sibling${j}0[$k] is not being used"
                                flag=1
                            fi
                        fi
                    done
                done
            done
        done

        #check if sibling cores of each cores in nova vcpu_pin_set are included in the same list.
        if [[ ! -z "${VCPUPINSET}" ]]; then
            for i in ${VCPUPINSET}; do
                for j in `seq 0 $(expr ${numa_nodes} - 1)` ; do
                    for k in `seq 0 $(expr ${cores_per_socket} - 1)`; do
                        if [[ $i = $sibling${j}0[$k] ]]; then
                            if [[ ! $(echo ${VCPUPINSET} |egrep  -o " $sibling${j}1[$k] |^$sibling${j}1[$k] | $sibling${j}1[$k]$" | wc -l ) = '1' ]]; then
                                echo "Sibling core of $i : $sibling${j}1[$k] is not being used in nova vcpu_pin_set" >&2
                                flag=1
                            fi
                        fi
                        if [[ $i = $sibling${j}1[$k] ]]; then
                            if [[ ! $(echo ${VCPUPINSET} |egrep  -o " $sibling${j}0[$k] |^$sibling${j}0[$k] | $sibling${j}0[$k]$" | wc -l ) = '1' ]]; then
                                echo "Sibling core of $i : $sibling${j}0[$k] is not being used in nova vcpu_pin_set"
                                flag=1
                            fi
                        fi
                    done
                done
            done
        fi

        #check if sibling cores are tuned in nova
        if [[ ! -z "${TUNED_CORES}" ]]; then
            for i in ${TUNED_CORES}; do
                for j in `seq 0 $(expr ${numa_nodes} - 1)` ; do
                    for k in `seq 0 $(expr ${cores_per_socket} - 1)`; do
                        if [[ $i = $sibling${j}0[$k] ]]; then
                            if [[ ! $(echo ${TUNED_CORES} |egrep  -o " $sibling${j}1[$k] |^$sibling${j}1[$k] | $sibling${j}1[$k]$" | wc -l ) = '1' ]]; then
                                echo "Tuned sibling core of $i : $sibling${j}1[$k] is not isolated in kernel" >&2
                                flag=1
                            fi
                        fi
                        if [[ $i = $sibling${j}1[$k] ]]; then
                            if [[ ! $(echo ${TUNED_CORES} |egrep  -o " $sibling${j}0[$k] |^$sibling${j}0[$k] | $sibling${j}0[$k]$" | wc -l ) = '1' ]]; then
                                echo "Tuned sibling core of $i : $sibling${j}0[$k] is not isolated in kernel" >&2
                                flag=1
                            fi
                        fi
                    done
                done
            done
        fi

        #check if sibling cores are isolated in nova
        if [[ ! -z "${ISOLCPUS}" ]]; then
            for i in ${ISOLCPUS}; do
                for j in `seq 0 $(expr ${numa_nodes} - 1)` ; do
                    for k in `seq 0 $(expr ${cores_per_socket} - 1)`; do
                        if [[ $i = $sibling${j}0[$k] ]]; then
                            if [[ ! $(echo ${ISOLCPUS} |egrep  -o " $sibling${j}1[$k] |^$sibling${j}1[$k] | $sibling${j}1[$k]$" | wc -l ) = '1' ]]; then
                                echo "Isolated sibling core of $i : $sibling${j}1[$k] is not isolated in kernel" >&2
                                flag=1
                            fi
                        fi
                    if [[ $i = $sibling${j}1[$k] ]]; then
                        if [[ ! $(echo ${instance_cpus} |egrep  -o " $sibling${j}0[$k] |^$sibling${j}0[$k] | $sibling${j}0[$k]$" | wc -l ) = '1' ]]; then
                            echo "Isolated sibling core of $i : $sibling${j}0[$k] is not isolated in kernel" >&2
                            flag=1
                        fi
                    fi
                done
            done
        done
    fi

        # instances are not overlapping pinned cpu.
        all_pinned_cores=''
        misconfigured_cores=''
        for libvirt_xml in `ls ${CITELLUS_ROOT}/etc/libvirt/qemu/instance-*.xml`; do
            all_pinned_cores="$(echo 'cat //cputune/vcpupin/@cpuset' | xmllint --shell ${libvirt_xml} | awk -F\" 'NR % 2 == 0 { print $2 }') "${all_pinned_cores}
        done
        for i in ${all_pinned_cores}; do
            if [[ ! $(echo ${all_pinned_cores} |egrep  -o " $i |^$i | $i$" | wc -l ) = '1' ]]; then
                misconfigured_cores=${misconfigured_cores}" ${i}"
            fi
        done
        if [[ ! -z "${misconfigured_cores}" ]]; then
            echo -ne "Multiple instance's pinned vcpus are overlapping Core(s) ${i} .\nThis may be an outcome of resize / live-migration on older version / live-migration of cpu pinned instances using destination host which will by-pass nova scheduler.\nLive-Migration of instances with pinned vcpus are not fully supported: https://access.redhat.com/solutions/2191071" >&2
            flag=1
        fi
    fi
fi


if [[ ${flag} -eq '1' ]]; then
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
