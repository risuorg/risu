#!/bin/bash

# Copyright (C) 2018  Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)

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
# priority: 400

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

# pti == meltdown, other 2 are spectrum
# echo 0 > /sys/kernel/debug/x86/pti_enabled
# noibrs noibpb nopti

secdisabled(){
    echo "This system has Meltdown security features disabled, please do check https://access.redhat.com/security/vulnerabilities/speculativeexecution for guidance" >&2
    exit ${RC_FAILED}
}

if is_lineinfile nopti ${CITELLUS_ROOT}/proc/cmdline; then
    secdisabled
fi

exit ${RC_OKAY}
