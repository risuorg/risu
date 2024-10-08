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

# long_name: systemd-sysv-generator failed to read a initscript
# description: Looks for systemd-sysv-generator "stat failed"
# priority: 700
# kb: https://access.redhat.com/solutions/3094591

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

REGEXP="systemd-sysv-generator\[[0-9]+\]: stat\(\) failed on "

if is_lineinfile "$REGEXP" ${journalctl_file}; then
    echo $'>>> systemd-sysv-generator "stat failed" detected' >&2
    grep -E "$REGEXP" ${journalctl_file} >&2
    exit ${RC_FAILED}
fi

# If the above conditions did not trigger RC_FAILED we are good.
exit ${RC_OKAY}
