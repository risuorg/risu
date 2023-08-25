#!/bin/bash

# Copyright (C) 2023 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

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

# long_name: Reports interfaces with errors
# description: Reports interfaces with errors
# priority: 900
# kb:

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

if [[ ${RISU_LIVE} -eq "0" ]]; then
    IP_ADDRESS_FILE=$(first_file_available "${RISU_ROOT}/sos_commands/networking/ip_-d_address" "${RISU_ROOT}/sos_commands/networking/ip_address")
    is_required_file "${IP_ADDRESS_FILE}"
elif [[ ${RISU_LIVE} -eq "1" ]]; then
    IP_ADDRESS_FILE=$(mktemp)
    trap 'rm ${IP_ADDRESS_FILE}' EXIT
    ip address >"${IP_ADDRESS_FILE}" 2>&1
fi

RC_STATUS=${RC_OKAY}

IFACES_IN_SYSTEM=$(grep -i "state UP" ${IP_ADDRESS_FILE} | cut -f2 -d ":" | tr -d " ")

# Check all interfaces
for iface in ${IFACES_IN_SYSTEM}; do
    IFACEPATH=$(find ${RISU_ROOT}/sys | grep net | grep ${iface} | grep -E 'errors|dropped|carrier_changes')

    for file in ${IFACEPATH}; do
        CONTENT=$(cat ${file})
        if [ $CONTENT != "0" ]; then
            echo "$iface detected errors on ${file//$RISU_ROOT/}: $CONTENT" >&2
            RC_STATUS=${RC_FAILED}

        fi
    done

done

exit ${RC_STATUS}
