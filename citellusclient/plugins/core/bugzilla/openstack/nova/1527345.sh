#!/bin/bash

# Copyright (C) 2017 Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)

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

# long_name: Missing format_dom in nova
# description: Checks for missing format_dom in nova
# bugzilla: https://bugzilla.redhat.com/show_bug.cgi?id=1527345
# priority: 800

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

is_required_file "${CITELLUS_ROOT}/var/log/nova/nova-compute.log"

if is_lineinfile 'libvirtError: XML error: Invalid PCI address 0000:00:00, at least one of domain, bus, or slot must be > 0' "${CITELLUS_ROOT}/var/log/nova/nova-compute.log"; then
    echo $"nova.conf https://bugzilla.redhat.com/show_bug.cgi?id=1527345" >&2
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
