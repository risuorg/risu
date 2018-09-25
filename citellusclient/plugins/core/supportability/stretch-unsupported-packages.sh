#!/bin/bash

# Copyright (C) 2018 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>


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

# check iptables || check firewalld

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

# long_name: Validate RHEL Firewall
# description: Validate RHEL firewall and check if is up
# priority: 200

function validate_firewall {
    # Check linux firewall to validate if it's running and active
    if is_active $1; then
        # True when service is up
        _SERVICE=0
    else
        # False when service is down
        _SERVICE=1
    fi

    echo ${_SERVICE}
}

OS=`discover_os`

if [[ "$OS" != "debian" ]]; then
    echo "Debian required" >&2
    exit ${RC_SKIPPED}
else
    echo $"The following installed packages have been deprecated as per release notes:"
    flag=0
    for package in fpm2 kedpm nagios3 net-tools iscsitarget; do
        if is_pkg $package >&2; then
            flag=1
        fi
    done
    if [[ "${flag}" == "1" ]]; then
        exit ${RC_FAILED}
    fi
fi
exit ${RC_OKAY}
