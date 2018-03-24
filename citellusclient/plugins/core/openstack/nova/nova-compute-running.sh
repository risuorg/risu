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

# we can run this against fs snapshot or live system

# long_name: Check for running nova-compute
# description: Reports if nova-compute is not running on compute node
# priority: 900

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

is_required_file "${CITELLUS_ROOT}/var/log/nova/nova-compute.log"
is_required_rpm openstack-nova-compute

if [[ -f "${CITELLUS_ROOT}/var/log/nova/nova-compute.log" ]]; then
    if ! is_process nova-compute; then
        echo "nova-compute process is not running" >&2
        exit ${RC_FAILED}
    fi
fi

exit ${RC_OKAY}
