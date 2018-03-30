#!/bin/bash

# Copyright (C) 2017   Robin Černín (rcernin@redhat.com)
# Copyright (C) 2018   Mikel Olasagasti Uranga (mikel@redhat.com)

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

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

# long_name: SELinux runtime status
# description: Determines runtime SELinux status
# priority: 100
# selinux enforcing

if [[ ${CITELLUS_LIVE} = 0 ]];  then
    is_required_file "${CITELLUS_ROOT}/sos_commands/selinux/sestatus_-b"
    sestatus="${CITELLUS_ROOT}/sos_commands/selinux/sestatus_-b"
else
    is_required_command "sestatus"
    sestatus=$(mktemp)
    trap "rm ${sestatus}" EXIT
    sestatus -b > ${sestatus}
fi

status=$(awk '/^SELinux status:/ {print $3}' ${sestatus})
if [[ "x$status" == "xenabled" ]]; then
    current_mode=$(awk '/^Current mode:/ {print $3}' "$sestatus")

    if [[ "x$current_mode" == "xenforcing" ]]; then
        exit ${RC_OKAY}
    else
        echo "persistent selinux mode is not enforcing (found $current_mode)" >&2
        exit ${RC_FAILED}
    fi
elif [[ "x$status" == "xdisabled" ]]; then
    echo "SELinux is disabled" >&2
    exit ${RC_FAILED}
else
    echo "failed to determined persistent selinux mode" >&2
    exit ${RC_FAILED}
fi
