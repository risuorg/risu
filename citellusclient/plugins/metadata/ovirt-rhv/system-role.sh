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

# long_name: returns the role of the system (hosted-engine-host)
# description: This plugin is used in various functions. It's just a metadata plugin.
# priority: 0

# Load common functions
[ -f "${CITELLUS_BASE}/common-functions.sh" ] && . "${CITELLUS_BASE}/common-functions.sh"

is_required_rpm qemu-kvm-rhev

ROLE="unknown"
if is_lineinfile "^vmid" ${CITELLUS_ROOT}/etc/ovirt-hosted-engine/hosted-engine.conf; then
    ROLE="hosted-engine-host"
else
    ROLE="ovirt-host"
fi

echo ${ROLE} >&2
exit ${RC_OKAY}
