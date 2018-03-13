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

# long_name: KVM Module loaded
# description: Checks for KVM module loaded
# priority: 900

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

# check baremetal node
is_required_file "${CITELLUS_ROOT}/proc/modules"
is_required_file "${CITELLUS_ROOT}/var/log/messages"

if is_lineinfile "libvirtd.*error.*virCapabilitiesDomainDataLookupInternal:746 : invalid argument: could not find capabilities for arch=x86_64 domaintype=kvm" "${CITELLUS_ROOT}/var/log/messages"; then
    if ! is_lineinfile "kvm_" "${CITELLUS_ROOT}/proc/modules"; then
        echo $"no KVM module loaded in /proc/modules" >&2
        exit ${RC_FAILED}
    fi
fi

exit ${RC_OKAY}