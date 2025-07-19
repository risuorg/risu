#!/bin/bash

# Copyright (C) 2021-2023 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

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
# priority: 890
# kb: https://access.redhat.com/solutions/3372291

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

REGEXP="systemd\[[0-9]+\]: Cannot add dependency job for unit ([^,]+), ignoring: Unit not found."

if is_lineinfile "$REGEXP" "${journalctl_file}"; then
    summary_printed=0
    for unit in $(perl -n -e "m#$REGEXP# && print \"\$1\\n\"" "${journalctl_file}"); do
        found=0
        for path in "/usr/lib/systemd/system/$unit" "/etc/systemd/system/$unit"; do
            [[ -L "${RISU_ROOT}/$path" ]] || continue
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
