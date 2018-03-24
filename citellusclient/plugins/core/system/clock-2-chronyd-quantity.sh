#!/bin/bash

# Copyright (C) 2018   Robin Černín (rcernin@redhat.com)

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

# long_name: ChronyD server quantity
# description: Checks for chronyd server quantity
# priority: 500

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

if ! is_active chronyd; then
    echo "chronyd is not running on this node" >&2
    exit ${RC_SKIPPED}
fi

is_required_file "${CITELLUS_ROOT}/etc/chrony.conf"
ncount=$(grep -c -E '^(peer|server)' "${CITELLUS_ROOT}/etc/chrony.conf")

if [[ "$ncount" -ge "4" ]]; then
    echo $"chronyd have a sufficient number of sources to choose from:" >&2
    flag=0
elif [[ "$ncount" -eq "3" ]]; then
    echo $"chronyd have minimum number of time sources needed to allow chronyd to detect 'falseticker':" >&2
    flag=1
elif [[ "$ncount" -eq "2" ]]; then
    echo $"chronyd have the worst possible configuration -- you'd be better off using just one ntp server:" >&2
    flag=1
elif [[ "$ncount" -eq "1" ]]; then
    echo $"chronyd configured with one server, if that one goes down, you are toast:" >&2
    flag=1
else
    echo $"chronyd not configured" >&2
    exit ${RC_FAILED}
fi
grep -E '^(peer|server)' "${CITELLUS_ROOT}/etc/chrony.conf" >&2
[[ "x$flag" = "x0" ]] && exit ${RC_OKAY} || exit ${RC_FAILED}
