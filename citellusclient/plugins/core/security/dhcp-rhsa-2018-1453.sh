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

# long_name: Checks for fixed dhcp package
# description: Checks if package dhclient is affected of remote execution flaw
# priority: 400

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

exitoudated(){
    echo "Please do check https://access.redhat.com/security/vulnerabilities/3442151 for guidance" >&2
}

RELEASE=$(discover_rhrelease)
[[ "${RELEASE}" -eq '0' ]] && echo "RH release undefined" >&2 && exit ${RC_SKIPPED}

if [[ "${RELEASE}" -eq "7" ]]; then
    exitoudated
    is_required_rpm_over dhclient dhclient-4.2.5-68.el7_5.1
elif [[ "${RELEASE}" -eq "6" ]]; then
    exitoudated
    is_required_rpm_over dhclient dhclient-4.1.1-53.P1.el6_9.4
fi
exit ${RC_OKAY}
