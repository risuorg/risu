#!/bin/bash

# Copyright (C) 2018 David Vallee Delisle (dvd@redhat.com)

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

# long_name: stores system UUID for correlation in webapp
# description: Sets system UUID

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

if [[ ${CITELLUS_LIVE} -eq 0 ]]; then
    DMIDECODE="${CITELLUS_ROOT}/dmidecode"
    is_required_file ${DMIDECODE}
    UUID=$(cat ${DMIDECODE} | grep -oP "UUID: \K(.*)")
elif [[ ${CITELLUS_LIVE} -eq 1 ]];then
    UUID=$(sudo dmidecode -s system-uuid)
fi

echo ${UUID} >&2
exit ${RC_OKAY}
