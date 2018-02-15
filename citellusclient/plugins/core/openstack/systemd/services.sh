#!/bin/bash

# Copyright (C) 2017   Robin Černín (rcernin@redhat.com)

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

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

# we can run this against fs snapshot or live system

# long_name: OpenStack failed services
# description: Checks for failed OSP services
# priority: 1000

if [[ "x$CITELLUS_LIVE" = "x1" ]];  then

    SERVICES=$(systemctl list-units --all | grep "neutron.*failed\|openstack.*failed\|openvswitch.*failed" | sed 's/*//' |awk '{print $1}')
    if systemctl list-units --all | grep -q "neutron.*failed\|openstack.*failed\|openvswitch.*failed"; then
        echo ${SERVICES} | tr ' ' '\n' >&2
        exit ${RC_FAILED}
    else
        exit ${RC_OKAY}
    fi
elif [[ "x$CITELLUS_LIVE" = "x0" ]];  then
    if [[ -z "${systemctl_list_units_file}" ]]; then
        echo "file /sos_commands/systemd/systemctl_list-units not found." >&2
        echo "file /sos_commands/systemd/systemctl_list-units_--all not found." >&2
        exit ${RC_SKIPPED}
    fi
    SERVICES=$(grep "neutron.*failed\|openstack.*failed\|openvswitch.*failed" "${systemctl_list_units_file}" | sed 's/*//' | awk '{print $1}')
    if grep -q "neutron.*failed\|openstack.*failed\|openvswitch.*failed" "${systemctl_list_units_file}"; then
        echo ${SERVICES} | tr ' ' '\n' >&2
        exit ${RC_FAILED}
    else
        exit ${RC_OKAY}
    fi
fi
