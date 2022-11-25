#!/bin/bash

# Copyright (C) 2018 David Valle Delisle <dvd@redhat.com>
# Copyright (C) 2018, 2020-2022 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

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

# long_name: returns the role of the system (controller, compute, etc) for OpenStack
# description: This plugin is used in various functions. It's just a metadata plugin.
# priority: 0

# Load common functions
[ -f "${RISU_BASE}/common-functions.sh" ] && . "${RISU_BASE}/common-functions.sh"

RELEASE=$(discover_osp_version)

if [[ ${RELEASE} != "0" ]]; then
    ROLE="unknown"
    if is_containerized; then
        ROLE="container-host"
    elif is_process ironic-conductor; then
        ROLE="undercloud"
    elif is_process nova-compute; then
        ROLE="compute"
    elif is_process pcsd; then
        ROLE="controller"
    elif is_process neutron-server; then
        # So if neutron-server is running and there's no pcsd, then it's a network node
        ROLE="network"
    elif is_process ceilometer-collector; then
        ROLE="telemetry"
    fi
else
    echo "Couldn't determine OSP release, probably not osp system" >&2
    exit ${RC_SKIPPED}
fi

echo ${ROLE} >&2
exit ${RC_OKAY}
