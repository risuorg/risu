#!/bin/bash

# Copyright (C) 2018 Juan Manuel Parrilla Madrid <jparrill@redhat.com>
# Copyright (C) 2018, 2020, 2021 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

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
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

# long_name: Validate RHEL Firewall
# description: Validate RHEL firewall and check if is up
# priority: 200

validate_firewall() {
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

OS=$(discover_os)

if [[ $OS == "debian" ]] || [[ $OS == "fedora" ]]; then
    _FW='firewalld'
else
    RH_RELEASE=$(discover_rhrelease)
    case ${RH_RELEASE} in
    6) _FW='iptables' ;;
    7) _FW='firewalld' ;;
    0) _FW='undef' ;;
    esac
fi

_STATUS=$(validate_firewall "${_FW}")

if [[ ${_STATUS} -eq 0 ]]; then
    exit ${RC_OKAY}
else
    echo "Service ${_FW} not active: ${_STATUS}" >&2
    exit ${RC_FAILED}
fi
