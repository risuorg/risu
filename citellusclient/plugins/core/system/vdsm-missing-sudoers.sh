#!/bin/bash

# Copyright (C) 2018 Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)

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

# long_name: Checks if sudoers misses the includedir directive and that makes fail vdsm
# description: Checks if sudoers misses the includedir directive that causes issues with vdsm and others
# priority: 800

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

# check baremetal node

if [[ "x$CITELLUS_LIVE" = "x0" ]]; then
    if [[ -z "${journalctl_file}" ]]; then
        echo "file /sos_commands/logs/journalctl_--no-pager_--boot not found." >&2
        echo "file /sos_commands/logs/journalctl_--all_--this-boot_--no-pager not found." >&2
    fi
    journal="$journalctl_file"
else
    journal="$(mktemp)"
    trap "/bin/rm ${journal}" EXIT
    journalctl -t systemd --no-pager --boot > ${journal}
fi

if is_lineinfile "Verify sudoer rules configuration" "${journal}" "${CITELLUS_ROOT}/var/log/messages"; then
    echo $"sudoers does miss entry for including sudoers.d folder and causes vdsm fail to start" >&2
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
