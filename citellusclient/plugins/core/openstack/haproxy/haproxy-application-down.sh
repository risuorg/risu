#!/bin/bash

# Copyright (C) 2018   Robin Černín (rcernin@redhat.com)

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

# we can run this against fs snapshot or live system

# long_name: Checks for HAProxy service is DOWN
# description: Checks whether there are any DOWN HAProxy services
# priority: 800

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

is_required_file "${CITELLUS_ROOT}/var/log/messages"

# Now check if we've the error message in logs:
if is_lineinfile "haproxy.*is DOWN" "${CITELLUS_ROOT}/var/log/messages"; then
    grep "haproxy.*is DOWN" "${CITELLUS_ROOT}/var/log/messages"| tail >&2
    exit ${RC_FAILED}
fi
exit ${RC_OKAY}
