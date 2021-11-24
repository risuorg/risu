#!/usr/bin/env bash
# Description: This script contains common functions to be used by risu plugins
#
# Copyright (C) 2018 Carsten Lichy-Bittendorf <clb@redhat.com>
# Copyright (C) 2018, 2019, 2020, 2021 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>
#
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

# Helper script to define location of various files.

discover_ocp_minor() {
    if is_rpm atomic-openshift >/dev/null 2>&1; then
        RPMINSTALLED=$(is_rpm atomic-openshift)
        VERSION=$(echo ${RPMINSTALLED} | cut -d "-" -f 3 | cut -d "." -f 1-3)
    else
        if is_rpm atomic-openshift-node >/dev/null 2>&1; then
            RPMINSTALLED=$(is_rpm atomic-openshift-node)
            VERSION=$(echo ${RPMINSTALLED} | cut -d "-" -f 4 | cut -d "." -f 1-3)
        else
            VERSION="0"
        fi
    fi
    echo ${VERSION}
}

discover_ocp_version() {
    discover_ocp_minor | cut -d "." -f 1-2
}

get_ocp_node_type() {
    OCPVERSION=$(discover_ocp_minor)
    OCPMINORVERSION=$(echo ${OCPVERSION} | awk -F "." '{print $2}')
    HNAME=$(cat ${RISU_ROOT}/etc/hostname)

    NODELISTFILELIST=$(find ${RISU_ROOT}/../../ -name *_all_nodes.out)
    for file in ${NODELISTFILELIST}; do
        NODELISTFILE=${file}
    done

    if [[ -f ${NODELISTFILE} ]] && [[ ${OCPMINORVERSION} -gt 8 ]]; then
        NODEROLE=$(grep ${HNAME} ${NODELISTFILE} | awk '{print $3}')
    elif is_rpm atomic-openshift-master >/dev/null 2>&1; then
        NODEROLE='master'
    elif [[ -f ${RISU_ROOT}/etc/origin/master/master-config.yaml ]]; then
        NODEROLE='master'
    elif is_rpm atomic-openshift-node >/dev/null 2>&1; then
        NODEROLE='node'
    else
        NODEROLE='unknown'
    fi
    echo ${NODEROLE}
}

discover_ocp_node_config() {
    export nodeconfig="dummyfile"
    nodeconfigs=("${RISU_ROOT}/etc/origin/node/node-config.yaml" "${RISU_ROOT}/../etc/origin/node/node-config.yaml" "${RISU_ROOT}/../tmp/node-config.yaml")

    # find available one and use it, the ones at back with highest priority
    for file in ${nodeconfigs[@]}; do
        [[ -f ${file} ]] && export nodeconfig="${file}"
    done
    echo ${nodeconfig}
}

discover_ocp_master_config() {
    export masterconfig="dummyfile"
    masterconfigs=("${RISU_ROOT}/etc/origin/master/master-config.yaml" "${RISU_ROOT}/../etc/origin/master/master-config.yaml")

    # find available one and use it, the ones at back with highest priority
    for file in ${masterconfigs[@]}; do
        [[ -f ${file} ]] && export masterconfig="${file}"
    done
    echo ${masterconfig}
}

discover_ocs_version() {
    OCSVERSION=$(cat ${RISU_ROOT}/../var/tmp/pssa/tmp/*ocs.out | grep 'access.redhat.com/rhgs3/rhgs' | awk -F ":" '{print $3}')
    OCSVERSION=$(cat ${RISU_ROOT}/../var/tmp/pssa/tmp/*ocs.out | grep 'access.redhat.com/rhgs3/rhgs' | awk -F ":" '{print $3}')
    OCSVERSION=$(cat ${RISU_ROOT}/../var/tmp/pssa/tmp/*ocs.out | grep 'access.redhat.com/rhgs3/rhgs' | awk -F ":" '{print $3}')
    ARR=($OCSVERSION)
    OCSVERSION=$(echo ${ARR[0]})
    OCSMAJORVERSION=$(echo "$OCSVERSION" | awk -F "." '{print $1}')
    OCSMINORVERSION=$(echo "$OCSVERSION" | awk -F "." '{print $2}')
    echo ${OCSVERSION}
}

calculate_cluster_pod_capacity() {
    DEFAULT_PODS_PER_CORE=10
    DEFAULT_MAX_PODS=250

    CLUSTERNODELIST=$(find ${RISU_ROOT}/../../ -maxdepth 1 -type d)

    MAXPODCLUSTER=0
    for nodes in ${CLUSTERNODELIST}; do
        if [ -d ${nodes}/sosreport-*/sos_commands ]; then
            PODS_PER_CORE=${DEFAULT_PODS_PER_CORE}
            MAX_PODS=${DEFAULT_MAX_PODS}
            NUMBER_CPU=$(grep 'CPU(s):' ${nodes}/sosreport-*/sos_commands/processor/lscpu)

            export nodeconfig=$(discover_ocp_node_config)
            XXX=$(cat ${nodeconfig} | grep 'pods-per-core:' -A1)
            ZZZ=$(cat ${nodeconfig} | grep 'max-pods:' -A1)

            if [[ -n ${XXX} ]]; then
                PODS_PER_CORE=($(echo ${XXX} | awk -F "['\"]" '{print $2}'))
            fi
            if [[ -n ${ZZZ} ]]; then
                MAX_PODS=($(echo ${ZZZ} | awk -F "['\"]" '{print $2}'))
            fi

            NOCPU=($(echo ${NUMBER_CPU} | awk -F " " '{print $2}'))
            ((CPUPODSPERCORE = NOCPU * PODS_PER_CORE))
            MAXPOD=$([[ $MAX_PODS -lt $CPUPODPERCORE ]] && echo "$MAX_PODS" || echo "$((NOCPU * PODS_PER_CORE))")
            MAXPODCLUSTER=$((MAXPODCLUSTER + MAXPOD))
        fi
    done
    echo ${MAXPODCLUSTER}
}
