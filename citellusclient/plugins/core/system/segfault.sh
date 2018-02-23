#!/bin/bash

# Copyright (C) 2018   Masaki Furuta (masaki@redhat.com)

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

# long_name: SEGV detector
# description: Looks for SEGV
# priority: 700

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

if [[ "x$CITELLUS_LIVE" = "x0" ]];  then
    if [[ -z "${journalctl_file}" ]]; then
        echo "file /sos_commands/logs/journalctl_--no-pager_--boot not found." >&2
        echo "file /sos_commands/logs/journalctl_--all_--this-boot_--no-pager not found." >&2
        exit ${RC_SKIPPED}
    fi

    if is_lineinfile "segfault at" "${journalctl_file}"; then
        echo "SEGV detected" >&2
        grep "segfault at" "${journalctl_file}" >&2
        exit ${RC_FAILED}
    fi

elif [[ "x$CITELLUS_LIVE" = "x1" ]]; then
    if journalctl -u kernel --no-pager --boot | grep -q "segfault at"; then
        echo "SEGV detected" >&2
        journalctl -u kernel --no-pager --boot | grep "segfault at" >&2
        exit ${RC_FAILED}
    fi
fi

# If the above conditions did not trigger RC_FAILED we are good.
exit ${RC_OKAY}

