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

# long_name: IPAddressGenerationFailure in DHCP Agent
# description: Looks for IP Address Generation Failure
# priority: 700

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"


REGEXP="IpAddressGenerationFailure No more IP addresses available on network"
FILE="${CITELLUS_ROOT}/var/log/neutron/dhcp-agent.log"

is_required_file ${FILE}

if is_lineinfile "${REGEXP}" ${FILE}; then
    echo $"Networks that run out of IP's:" >&2
    LANG=C grep "${REGEXP}" ${FILE} |cut -d " " -f 17|sort|uniq >&2
    exit ${RC_FAILED}
fi

# If the above conditions did not trigger RC_FAILED we are good.
exit ${RC_OKAY}
