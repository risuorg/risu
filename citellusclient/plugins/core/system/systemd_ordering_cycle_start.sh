#!/bin/bash

# Copyright (C) 2018   Renaud Métrich (rmetrich@redhat.com)

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

# long_name: systemd deleted a 'start' job because of an ordering cycle
# description: Looks for "Breaking ordering cycle .../start" messages
# priority: 700

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

REGEXP="Breaking ordering cycle by deleting job ([^/]+)/start"

if [[ "x$CITELLUS_LIVE" = "x0" ]]; then
    if [[ -z "${journalctl_file}" ]]; then
        echo "file /sos_commands/logs/journalctl_--no-pager_--boot not found." >&2
        echo "file /sos_commands/logs/journalctl_--all_--this-boot_--no-pager not found." >&2
        exit ${RC_SKIPPED}
    fi
    journal="$journalctl_file"
else
    journal="$(mktemp)"
    trap "/bin/rm ${journal}" EXIT
    journalctl -t systemd --no-pager --boot > ${journal}
fi

if is_lineinfile "$REGEXP" ${journal}; then
    echo $">>> systemd deleted some 'start' jobs" >&2
    egrep "$REGEXP" ${journal} >&2
    exit ${RC_FAILED}
fi

# If the above conditions did not trigger RC_FAILED we are good.
exit ${RC_OKAY}
