#!/bin/bash

# Copyright (C) 2018   Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)
# Based on code snippet by Miguel Ángel Ajo Pelayo (majopela@redhat.com)

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

# long_name: Check for ovs ports in no namespace
# description: Checks for ovs ports in no namespace
# priority: 800

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

if [[ ${CITELLUS_LIVE} -eq 0 ]]; then
    FILE="${CITELLUS_ROOT}/sos_commands/openvswitch/ovsdb-client_-f_list_dump"
    is_required_directory "${CITELLUS_ROOT}/sos_commands/networking/"

    NICS=$(mktemp)
    trap "rm ${NICS}" EXIT

    ls ${CITELLUS_ROOT}/sos_commands/networking/ > ${NICS}

elif [[ ${CITELLUS_LIVE} -eq 1 ]];then
    FILE=$(mktemp)
    trap "rm ${FILE}" EXIT
    ovsdb-client -f list dump > ${FILE}

    NICS=$(mktemp)
    trap "rm ${NICS}" EXIT
    ls /proc/sys/net/ipv*/conf |grep -v "sys/net"|sort|uniq > ${NICS}
fi

is_required_file "${FILE}"

PREPORTS="$(cat ${FILE}|egrep '(ha-|qr-|gq-)'|cut -d\" -f2)"
PREPORTS="${PREPORTS} $(cat ${FILE}|grep name|grep tap|cut -d\" -f2)"

PORTS=`echo ${PREPORTS}|tr " " "\n"|sort|uniq`

echo "ports not in any router or namespace" >&2
flag=0

for port in ${PORTS}; do
    grep ${port} ${NICS} &> /dev/null
    if [[ "$?" != "0" ]]; then
        echo ${port} >&2
        flag=1
    fi
done

if [[ ${flag} -eq '1' ]]; then
    exit ${RC_FAILED}
fi

exit ${RC_OKAY}
