#!/bin/bash

# Copyright (C) 2018 David Vallee Delisle (dvd@redhat.com)

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

# long_name: Live migration issue
# description: Conflicts with use by a block device
# bugzilla: https://bugzilla.redhat.com/show_bug.cgi?id=1482478
# priority: 600

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

# we can run this against fs snapshot or live system

# check if we are running against compute

if ! is_process nova-compute; then
    echo "works only on compute node" >&2
    exit ${RC_SKIPPED}
fi

# we know the exact kernel versions for RHEL7 from https://access.redhat.com/articles/3078

is_lineinfile "Conflicts with use by a block device" ${CITELLUS_ROOT}/var/log/libvirt/qemu/instance*.log
if [[ $? -gt 0 ]]; then
    echo $"https://bugzilla.redhat.com/show_bug.cgi?id=1482478" >&2
    exit ${RC_OKAY}
else
    exit ${RC_FAILED}
fi
