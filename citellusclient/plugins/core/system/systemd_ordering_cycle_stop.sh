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

# long_name: systemd deleted a 'stop' job because of an ordering cycle
# description: Looks for "Breaking ordering cycle ... /stop" messages
# priority: 400

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

REGEXP="Breaking ordering cycle by deleting job ([^/]+)/stop"

is_required_file "${CITELLUS_ROOT}/var/log/messages"

if is_lineinfile "$REGEXP" "${CITELLUS_ROOT}/var/log/messages"; then
    echo $">>> systemd deleted some 'stop' jobs" >&2
    egrep "$REGEXP" "${CITELLUS_ROOT}/var/log/messages" >&2
    exit ${RC_FAILED}
fi

# If the above conditions did not trigger RC_FAILED we are good.
exit ${RC_OKAY}
