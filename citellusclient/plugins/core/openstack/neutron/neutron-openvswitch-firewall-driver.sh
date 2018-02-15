#!/bin/bash

# Copyright (C) 2018   Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)

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

# long_name: Check OSP10 and firewall configuration not supported
# description: Checks for invalid OSP10 firewall configuration in neutron
# priority: 200

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

# Find release
RELEASE=$(discover_osp_version)

if [[ "x$RELEASE" != "x10" ]]; then
    echo "This affects only OSP10" >&2
    exit ${RC_SKIPPED}
fi

if [[ "$(iniparser ${CITELLUS_ROOT}/etc/neutron/plugins/ml2/openvswitch_agent.ini securitygroup firewall_driver)" == 'openvswitch' ]]; then
    echo $"Unsupported firewall_driver = openvswitch in deployment" >&2
    exit ${RC_FAILED}
fi

exit ${RC_OKAY}
