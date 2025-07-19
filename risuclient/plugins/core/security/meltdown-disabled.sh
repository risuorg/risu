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

# long_name: Checks for disabled kernel protection features against Meltdown
# description: Checks if user disabled fix for Meltdown
# priority: 920
# bugzilla: https://bugzilla.redhat.com/show_bug.cgi?id=1519778
# kb: https://access.redhat.com/security/vulnerabilities/speculativeexecution

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

# pti == meltdown, other 2 are spectrum
# echo 0 > /sys/kernel/debug/x86/pti_enabled
# noibrs noibpb nopti

secdisabled() {
    echo "This system has Meltdown security features disabled, please do check https://access.redhat.com/security/vulnerabilities/speculativeexecution for guidance" >&2
    exit ${RC_FAILED}
}

if is_lineinfile nopti ${RISU_ROOT}/proc/cmdline; then
    secdisabled
fi

exit ${RC_OKAY}
