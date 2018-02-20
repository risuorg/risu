#!/bin/bash

# Copyright (C) 2018 Luca Miccini <luca.miccini@redhat.com>

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

# long_name: Checks whether ipv6 has been disabled via sysctl
# description: Reports if ipv6 has been disabled via sysctl
# priority: 900

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

# Check if we're osp node or exit
is_required_rpm pacemaker
is_required_rpm openstack-selinux

files=$(find ${CITELLUS_ROOT}/etc/sysctl.* -type f 2>/dev/null)

if is_lineinfile "disable_ipv6=1" ${files}; then
    echo $"ipv6 is disabled, there could be issues with rabbitmq." >&2
    exit ${RC_FAILED}
fi

exit ${RC_OKAY}
