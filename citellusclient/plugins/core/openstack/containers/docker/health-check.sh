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

# description: Check docker container health-check states

# Load common functions
[ -f "${CITELLUS_BASE}/common-functions.sh" ] && . "${CITELLUS_BASE}/common-functions.sh"

if is_process nova-compute;then
        echo "works only on controller node" >&2
        exit $RC_SKIPPED
fi

# Setup the file we'll be using for using similar approach on Live and non-live

is_required_containerized

if [ "x$CITELLUS_LIVE" = "x1" ]; then
    ncontainers=$(docker ps | grep -v NAMES | wc -l)
    unhealthy_containers=$(docker ps | grep -i -c unhealthy)
    if [[ "${unhealthy_containers}" -ge "1" ]]; then
        echo $"unhealthy containers detected (${unhealthy_containers}/${ncontainers}):" >&2
        docker ps | grep -i "unhealthy" | awk '{print $NF}' >&2
        exit $RC_FAILED
    else
        echo $"no unhealthy containers detected" >&2
        exit $RC_OKAY
    fi
elif [ "x$CITELLUS_LIVE" = "x0" ]; then
    is_required_file "${CITELLUS_ROOT}/sos_commands/docker/docker_ps"
    ncontainers=$(grep -v NAMES "${CITELLUS_ROOT}/sos_commands/docker/docker_ps" | wc -l)
    unhealthy_containers=$(grep -i -c unhealthy "${CITELLUS_ROOT}/sos_commands/docker/docker_ps")
    if [[ "${unhealthy_containers}" -ge "1" ]]; then
        echo $"unhealthy containers detected (${unhealthy_containers}/${ncontainers}):" >&2
        grep -i "unhealthy" "${CITELLUS_ROOT}/sos_commands/docker/docker_ps" | awk '{print $NF}' >&2
        exit $RC_FAILED
    else
        echo $"no unhealthy containers detected" >&2
        exit $RC_OKAY
    fi 
fi
