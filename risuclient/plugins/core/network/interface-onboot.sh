#!/bin/bash

# Copyright (C) 2020, 2021 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>
# Copyright (C) 2020 Volkan Yalcin <vlyalcin@gmail.com>

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

# long_name: Reports interfaces that its state 'up' and doesn't have ONBOOT='yes' in its network-scripts file.
# description: Reports interfaces that its state 'up' and doesn't have ONBOOT='yes' in its network-scripts file.
# bugzilla: https://github.com/risuorg/risu/issues/535
# priority: 100
# kb:

# Test cases
# 1 Give an invalid SOS_IP_ADDRESS_PATHS. Observe the fail.
# 2 Remove ONBOOT=yes from network file for the UP interfaces. Observe the fail.

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

RH_RELEASE=$(discover_rhrelease)

if [[ ${RH_RELEASE} -ge 9 ]]; then
    echo "EL9 no longer uses ifcfg files for configuration" >&2
    exit ${RC_SKIPPED}
fi

NETWORK_SCRIPTS_PATH="/etc/sysconfig/network-scripts/ifcfg"

if [[ ${RISU_LIVE} -eq "0" ]]; then
    NETWORK_SCRIPTS_PATH="${RISU_ROOT}${NETWORK_SCRIPTS_PATH}"
    IP_ADDRESS_FILE=$(first_file_available "${RISU_ROOT}/sos_commands/networking/ip_-d_address" "${RISU_ROOT}/sos_commands/networking/ip_address")
    is_required_file "${IP_ADDRESS_FILE}"
elif [[ ${RISU_LIVE} -eq "1" ]]; then
    IP_ADDRESS_FILE=$(mktemp)
    trap 'rm ${IP_ADDRESS_FILE}' EXIT
    ip address >"${IP_ADDRESS_FILE}" 2>&1
fi

RC_STATUS=${RC_OKAY}

# Now check for ONBOOT=YES missing on the interface files for above macs
# There are several approaches:
# NIC is defined via IFACE name
# NIC is defined via MAC via HWADDR
# NIC is up as it's part of bridge, etc

# Sometimes NIC might have a fancy name instead of ifcfg-$IFNAME, use MACs for matching
MACS_IN_SYSTEM=$(grep -i -a2 "state UP" ${IP_ADDRESS_FILE} | grep ether | awk '{print $2}' | sort -u)
IFACES_IN_SYSTEM=$(grep -i "state UP" ${IP_ADDRESS_FILE} | cut -f2 -d ":" | tr -d " ")
declare -A IFACES_MACS

for iface in ${IFACES_IN_SYSTEM}; do
    # Fill array of IFACES-MACS
    IFACES_MACS[${iface}]=$(cat ${IP_ADDRESS_FILE} | grep ${iface} -A2 | grep ether | awk '{print $2}')
done

# Check all interfaces
for iface in ${IFACES_IN_SYSTEM}; do
    mac=${IFACES_MACS[$iface]}
    if ! is_lineinfile ${mac} ${RISU_ROOT}/etc/sysconfig/network-scripts/ifcfg-*; then
        # mac is not there, so check iface based on name
        if ! is_lineinfile ${iface} ${RISU_ROOT}/etc/sysconfig/network-scripts/ifcfg-*; then
            echo "Interface ${iface} with MAC ${mac} is in state UP but not defined in ifcfg-* files" >&2
            RC_STATUS=${RC_FAILED}
        fi
    fi

    # For each iface, check that onboot=yes is there
    for ifacefile in ${RISU_ROOT}/etc/sysconfig/network-scripts/ifcfg-*; do
        if is_lineinfile ${iface} ${ifacefile}; then
            NETWORK_INTERFACE_FILE=${ifacefile}
            status=$(cat ${NETWORK_INTERFACE_FILE} | grep -i onboot | grep -v ^# | cut -d "=" -f 2- | xargs echo | tr "[:upper:]" "[:lower:]")
            if [ ${status} != "yes" ]; then
                echo "Interface '${iface}' up but not 'onboot=YES' in the ${NETWORK_INTERFACE_FILE} file!" >&2
                RC_STATUS=${RC_FAILED}
            fi
        fi
    done
done

exit ${RC_STATUS}
