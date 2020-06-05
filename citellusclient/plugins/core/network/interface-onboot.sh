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
SOS_IP_ADDRESS_PATHS="sos_commands/networking/ip_-d_address sos_commands/networking/ip_address"

if [[ ${CITELLUS_LIVE} -eq 0 ]]; then
    NETWORK_SCRIPTS_PATH="${CITELLUS_ROOT}${NETWORK_SCRIPTS_PATH}"
    IP_ADDRESS_FILE=""
    for SOS_IP_ADDRESS_PATH in ${SOS_IP_ADDRESS_PATHS}; do
        if [ -f "${CITELLUS_ROOT}/${SOS_IP_ADDRESS_PATH}" ]; then
            IP_ADDRESS_FILE="${CITELLUS_ROOT}/${SOS_IP_ADDRESS_PATH}"
            break
        fi
    done
    if [ -z "$IP_ADDRESS_FILE" ]; then
      echo "There is no 'ip address' command result file in the sosreport" >&2
      echo "List of the known paths: $SOS_IP_ADDRESS_PATHS" >&2
      exit ${RC_FAILED}
    fi
elif [[ ${CITELLUS_LIVE} -eq 1 ]]; then
    IP_ADDRESS_FILE=$(mktemp)
    trap "rm ${IP_ADDRESS_FILE}" EXIT
    ip address  > ${IP_ADDRESS_FILE} 2>&1
fi

for interface_name in $(grep -i "state UP" ${IP_ADDRESS_FILE} |cut -f2 -d ":"); do
        if EMIT_RETURN=$(grep -i "onboot=yes" "${NETWORK_SCRIPTS_PATH}-${interface_name}"); then
            echo "[OK] Interface '$interface_name' up and 'onboot=YES' in the '${NETWORK_SCRIPTS_PATH}-${interface_name}' file!" >&2
        else
            echo "[FAIL] Interface '$interface_name' up but not 'onboot=YES' in the ${NETWORK_SCRIPTS_PATH}-${interface_name} file!" >&2
            exit ${RC_FAILED}
        fi
done

exit ${RC_OKAY}
