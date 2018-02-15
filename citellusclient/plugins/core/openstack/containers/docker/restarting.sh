#!/bin/bash

# Copyright (C) 2017   Robin Černín (rcernin@redhat.com)

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

# we can run this on fs snapshot or live system

# long_name: Containers in restarting state
# description: Check docker container restarting states
# priority: 700

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

is_required_containerized

if [[ ${CITELLUS_LIVE} -eq 0 ]]; then
    is_required_file "${CITELLUS_ROOT}/sos_commands/docker/docker_ps"
    FILE="${CITELLUS_ROOT}/sos_commands/docker/docker_ps"
elif [[ ${CITELLUS_LIVE} -eq 1 ]];then
    FILE=$(mktemp)
    trap "rm ${FILE}" EXIT
    docker ps > ${FILE}
fi

ncontainers=$(grep -v NAMES "${FILE}" | wc -l)
restarting_containers=$(grep -i -c restarting "${FILE}")
if [[ "${restarting_containers}" -ge "1" ]]; then
    echo $"restarting containers detected (${restarting_containers}/${ncontainers}):" >&2
    grep -i "restarting" "${FILE}" | awk '{print $NF}' >&2
    exit ${RC_FAILED}
else
    echo $"no restarting containers detected" >&2
    exit ${RC_OKAY}
fi
