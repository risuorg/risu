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

# long_name: systemd didn't start a unit because it was not found
# description: Looks for "Cannot add dependency job ..." messages
# priority: 400

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

REGEXP="systemd\[[0-9]+\]: Cannot add dependency job for unit ([^,]+), ignoring: Unit not found."

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

if is_lineinfile "$REGEXP" "${journal}"; then
    summary_printed=0
    for unit in $(perl -n -e "m#$REGEXP# && print \"\$1\\n\"" "${journal}"); do
        found=0
        for path in "/usr/lib/systemd/system/$unit" "/etc/systemd/system/$unit"; do
            [[ -L "${CITELLUS_ROOT}/$path" ]] || continue
            found=1
            break
        done
        [[ ${found} -eq 1 ]] || continue
        if [[ ${summary_printed} -eq 0 ]]; then
            summary_printed=1
            echo $">>> systemd couldn't find some units (symlinks to non-root filesystem)" >&2
        fi
        echo "$path" >&2
    done
    exit ${RC_FAILED}
fi

# If the above conditions did not trigger RC_FAILED we are good.
exit ${RC_OKAY}
