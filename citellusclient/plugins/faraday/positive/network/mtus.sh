#!/bin/bash

# Copyright (C) 2018 Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)

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

# long_name: Metadata generator for MTU's for nics
# description: Generates keypairs for MTU's for nics
# priority: 800

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

# Code for generating items for faraday-CSV

if [[ ${CITELLUS_LIVE} -eq 0 ]]; then
    FILE="${CITELLUS_ROOT}/sos_commands/networking/ip_address"
elif [[ ${CITELLUS_LIVE} -eq 1 ]];then
    FILE=$(mktemp)
    trap "rm ${FILE}" EXIT
    ip address  > ${FILE} 2>&1
fi

is_required_file ${FILE}

cat ${FILE}|awk '/^[0-9].*(br|tun|lan|docker|ovs).*:/ {print $2 $5}'|tr "\n" ";" >&2
exit ${RC_OKAY}
