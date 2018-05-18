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

# long_name: Physical machine
# description: Reports hypervisor technology in use
# priority: 100

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

# check baremetal node

if [[ "x$CITELLUS_LIVE" = "x0" ]];  then
    is_required_file "${CITELLUS_ROOT}/sos_commands/hardware/dmidecode"

    is_lineinfile "Product Name: VMware" "${CITELLUS_ROOT}/sos_commands/hardware/dmidecode" && echo "VMware" >&2 && exit ${RC_FAILED}
    is_lineinfile "Product Name: VirtualBox" "${CITELLUS_ROOT}/sos_commands/hardware/dmidecode" && echo "Virtualbox" >&2 && exit ${RC_FAILED}
    is_lineinfile "Product Name: KVM|Manufacturer: QEMU" "${CITELLUS_ROOT}/sos_commands/hardware/dmidecode" && echo "KVM" >&2 && exit ${RC_FAILED}
    is_lineinfile "Product Name: Bochs" "${CITELLUS_ROOT}/sos_commands/hardware/dmidecode" && echo "Bochs" >&2 && exit ${RC_FAILED}
    exit ${RC_OKAY}

elif [[ "x$CITELLUS_LIVE" = "x1" ]]; then
    if dmidecode | grep -q "Product Name: VMware" ; then
        echo "VMware" >&2
        exit ${RC_FAILED}
    elif dmidecode | grep -q "Product Name: VirtualBox"; then
        echo "Virtualbox" >&2
        exit ${RC_FAILED}
    elif dmidecode | egrep -q "Product Name: KVM|Manufacturer: QEMU"; then
        echo "KVM" >&2
        exit ${RC_FAILED}
    elif dmidecode | grep -q "Product Name: Bochs"; then
        echo "Bosch" >&2
    else
        exit ${RC_OKAY}
    fi
fi
