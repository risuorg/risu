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

# long_name: Kernel OOM-killer, panic or soft lockup
# description: Looks for the Kernel Out of Memory, panics and soft locks
# priority: 700

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

if [[ "x$CITELLUS_LIVE" = "x0" ]];  then
    if [[ -z "${journalctl_file}" ]]; then
        echo "file /sos_commands/logs/journalctl_--no-pager_--boot not found." >&2
        echo "file /sos_commands/logs/journalctl_--all_--this-boot_--no-pager not found." >&2
        exit ${RC_SKIPPED}
    fi
    is_lineinfile "oom-killer" "${journalctl_file}" && echo "oom-killer detected" >&2 && flag=1
    is_lineinfile "soft lockup" "${journalctl_file}" && echo "soft lockup detected" >&2 && flag=1
    is_lineinfile "blocked for more than 120 seconds"  "${journalctl_file}" && echo "hung task detected"  >&2 && flag=1

elif [[ "x$CITELLUS_LIVE" = "x1" ]]; then
    if journalctl -u kernel --no-pager --boot | grep -q "oom-killer"; then
        echo "oom-killer detected" >&2
        flag=1
    fi
    if journalctl -u kernel --no-pager --boot | grep -q "soft lockup"; then
        echo "soft lockup detected" >&2
        flag=1
    fi
    if journalctl -u kernel --no-pager --boot | grep -q "blocked for more than 120 seconds"; then
        echo "hung task detected" >&2
        flag=1
    fi
fi

if [[ "x$flag" = "x1" ]]; then
    exit ${RC_FAILED}
else
# If the above conditions did not trigger RC_FAILED we are good.
    exit ${RC_OKAY}
fi
