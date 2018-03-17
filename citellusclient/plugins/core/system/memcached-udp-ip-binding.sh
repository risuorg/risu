#!/bin/bash

# Copyright (C) 2018 Mikel Olasagasti Uranga (mikel@redhat.com)

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

# long_name: check memcached options, UDP and IP binding
# description: check memcached options, if UDP is disabled and if is binded to an IP
# priority: 100

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

ERRORMSG1=$"Memcached with default options"
ERRORMSG2=$"Memcached doesn't have UDP disabled"
ERRORMSG3=$"Memcached doesn't have any IP binding"

if is_rpm memcached > /dev/null 2>&1; then
    is_required_file "${CITELLUS_ROOT}/etc/sysconfig/memcached"
    OPTIONS=$(grep "^OPTIONS" "${CITELLUS_ROOT}/etc/sysconfig/memcached")
    if [[ -z "${OPTIONS}" ]] || [[ $(echo ${OPTIONS} |cut -d "=" -f2) == "\"\"" ]]; then
        echo ${ERRORMSG1} >&2
        exit ${RC_FAILED}
    fi
    if [[ "x$(echo ${OPTIONS} |grep "\-U 0" -c)" == "x0" ]]; then
        echo ${ERRORMSG2} >&2
        error=1
        exit ${RC_FAILED}
    elif [[ "x$(echo ${OPTIONS} |grep "\-l" -c)" == "x0" ]]; then
        echo ${ERRORMSG3} >&2
        error=1
        exit ${RC_FAILED}
    fi

    if [[ ${error} == 1 ]]; then
        exit ${RC_FAILED}
    fi
fi

# exit as OK if haven't failed earlier
exit ${RC_OKAY}
