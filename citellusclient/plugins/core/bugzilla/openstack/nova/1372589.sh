#!/bin/bash

# Copyright (C) 2018   Robin Černín (rcernin@redhat.com)

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

# this can run against live and also any sort of snapshot of the filesystem

# long_name: QEMU configuration max_files and max_processes
# description: Verify qemu.conf max_files and max_processes
# bugzilla: https://bugzilla.redhat.com/show_bug.cgi?id=1372589
# priority: 500

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

is_required_file "${CITELLUS_ROOT}/etc/libvirt/qemu.conf"

max_files=$(iniparser "${CITELLUS_ROOT}/etc/libvirt/qemu.conf" max_files)
max_processes=$(iniparser "${CITELLUS_ROOT}/etc/libvirt/qemu.conf" max_processes)

if [[ "${max_files}" -ge "32768" ]] || [[ "${max_processes}" -ge "131072" ]]; then
    echo $"max_files is set to ${max_files}" >&2
    echo $"max_processes is set to ${max_processes}" >&2
    echo $"https://bugzilla.redhat.com/show_bug.cgi?id=1372589" >&2
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
