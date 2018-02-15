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

# long_name: Ceph status
# description: Checks Ceph status on node
# priority: 800

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

# Check if ceph was integrated, if yes then check it's health

if [[ "x$CITELLUS_LIVE" = "x0" ]]; then
    if [[ -z "${systemctl_list_units_file}" ]]; then
        echo "file /sos_commands/systemd/systemctl_list-units not found." >&2
        echo "file /sos_commands/systemd/systemctl_list-units_--all not found." >&2
        exit ${RC_SKIPPED}
    else
        if grep -q "ceph-mon.* active" "${systemctl_list_units_file}"; then
            is_required_file "${CITELLUS_ROOT}/sos_commands/ceph/ceph_health_detail"
            is_required_file "${CITELLUS_ROOT}/etc/ceph/ceph.conf"
            is_lineinfile "HEALTH_OK" "${CITELLUS_ROOT}/sos_commands/ceph/ceph_health_detail" && exit ${RC_OKAY} || cat "${CITELLUS_ROOT}/sos_commands/ceph/ceph_health_detail" >&2 && exit ${RC_FAILED}
        else
            echo "no ceph integrated" >&2
            exit ${RC_SKIPPED}
        fi
    fi
elif [[ "x$CITELLUS_LIVE" = "x1" ]]; then
    if hiera -c /etc/puppet/hiera.yaml enabled_services | egrep -sq ceph_mon; then
        if ceph -s | grep -q HEALTH_OK; then
            exit ${RC_OKAY}
        else
            ceph -s | grep health >&2
            exit ${RC_FAILED}
        fi
    else
        echo "no ceph integrated" >&2
        exit ${RC_SKIPPED}
    fi
fi
