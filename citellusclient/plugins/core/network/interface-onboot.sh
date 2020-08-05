#!/bin/bash

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
# bugzilla: https://github.com/citellusorg/citellus/issues/535
# priority: 100
# kb:

# Test cases
# 1 Give an invalid SOS_IP_ADDRESS_PATHS. Observe the fail.
# 2 Remove ONBOOT=yes from network file for the UP interfaces. Observe the fail.

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

NETWORK_SCRIPTS_PATH="/etc/sysconfig/network-scripts/ifcfg"

if [[ "${CITELLUS_LIVE}" -eq "0" ]]; then
    NETWORK_SCRIPTS_PATH="${CITELLUS_ROOT}${NETWORK_SCRIPTS_PATH}"
    IP_ADDRESS_FILE=$(first_file_available "${CITELLUS_ROOT}/sos_commands/networking/ip_-d_address" "${CITELLUS_ROOT}/sos_commands/networking/ip_address")
    is_required_file "${IP_ADDRESS_FILE}"
elif [[ "${CITELLUS_LIVE}" -eq "1" ]]; then
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
IFACES_IN_SYSTEM=$(grep -i "state UP" ${IP_ADDRESS_FILE} | cut -f2 -d ":")
declare -A IFACES_MACS

for iface in ${IFACES_IN_SYSTEM}; do
    # Fill array of IFACES-MACS
    IFACES_MACS[${iface}]=$(cat ${IP_ADDRESS_FILE} | grep ${iface} -A2 | grep ether | awk '{print $2}')
done

# Check all interfaces
for iface in ${IFACES_IN_SYSTEM}; do
    mac=${IFACES_MACS[$iface]}
    if ! is_lineinfile ${mac} ${CITELLUS_ROOT}/etc/sysconfig/network-scripts/ifcfg-*; then
        # mac is not there, so check iface based on name
        if ! is_lineinfile ${iface} ${CITELLUS_ROOT}/etc/sysconfig/network-scripts/ifcfg-*; then
            echo "Interface ${iface} with MAC ${mac} is in state UP but not defined in ifcfg-* files" >&2
            RC_STATUS=${RC_FAILED}
        fi
    fi

    # For each iface, check that onboot=yes is there
    for ifacefile in ${CITELLUS_ROOT}/etc/sysconfig/network-scripts/ifcfg-*; do
        if is_lineinfile ${iface} ${ifacefile}; then
            NETWORK_INTERFACE_FILE=${ifacefile}
            if ! is_lineinfile 'onboot=yes' ${NETWORK_INTERFACE_FILE}; then
                echo "Interface '$interface_name' up but not 'onboot=YES' in the ${NETWORK_INTERFACE_FILE} file!" >&2
                RC_STATUS=${RC_FAILED}
            fi
        fi
    done
done

exit ${RC_STATUS}
