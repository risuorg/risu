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

# we can run this against fs snapshot or live system

# long_name: Detect duplicate iptables rule warning
# description: Detects duplicate iptables rule warning
# priority: 600

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

is_required_file "${RISU_ROOT}/var/log/neutron/l3-agent.log"

if is_lineinfile "Duplicate iptables rule detected" "${RISU_ROOT}/var/log/neutron/l3-agent.log"; then
    grep -i 'Duplicate iptables rule detected' "${RISU_ROOT}/var/log/neutron/l3-agent.log" | grep -oP "^([0-9\-]+)" | uniq -c | tail >&2
    exit ${RC_FAILED}
fi

exit ${RC_OKAY}
