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
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

# long_name: External connectivity test
# description: Checks for external connectivity of the system
# priority: 100

: ${REMOTE_PING_TARGET:=8.8.8.8}

if [[ ! "x$CITELLUS_LIVE" = "x1" ]]; then
    echo "works on live-system only" >&2
    exit ${RC_SKIPPED}
fi

gw=$(ip route | awk '$1 == "default" {print $3}')
echo "default gateway is: $gw" >&2

if ! ping -c1 ${gw} >/dev/null 2>&1; then
    echo $"default gateway is unreachable" >&2
    RC=${RC_FAILED}
else
    echo "default gateway is reachable" >&2
    RC=${RC_OKAY}
fi

if ! ping -c1 ${REMOTE_PING_TARGET} >/dev/null 2>&1; then
    echo "remote target @ $REMOTE_PING_TARGET is unreachable" >&2
    RC=${RC_FAILED}
else
    echo "remote target @ $REMOTE_PING_TARGET is reachable" >&2
    RC=${RC_OKAY}
fi

exit ${RC}
