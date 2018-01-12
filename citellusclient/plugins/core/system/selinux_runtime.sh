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

# Load common functions
[ -f "${CITELLUS_BASE}/common-functions.sh" ] && . "${CITELLUS_BASE}/common-functions.sh"

# long_name: SELinux runtime status
# description: Determines runtime SELinux status
# priority: 100
# selinux enforcing

if [[ $CITELLUS_LIVE = 0 ]];  then
    is_required_file "${CITELLUS_ROOT}/sos_commands/selinux/sestatus_-b"
    mode=$(awk '/^Current mode:/ {print $3}' "${CITELLUS_ROOT}/sos_commands/selinux/sestatus_-b")
else
    mode=$(sestatus -b | awk '/^Current mode:/ {print $3}')
fi

if ! [[ "$mode" ]]; then
    echo $"failed to determined runtime selinux mode" >&2
    exit $RC_FAILED
fi

if [[ $mode != enforcing ]]; then
    echo -n $"runtime selinux mode is not enforcing" >&2
    echo " (found $mode)" >&2
    exit $RC_FAILED
else
    exit $RC_OKAY
fi
