#!/usr/bin/env bash
# Description: This script contains common functions to be used by citellus plugins
#
# Copyright (C) 2018 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>
#
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

# Helper script to define location of various files.

virt_type(){
    if [[ "x$CITELLUS_LIVE" = "x0" ]]; then
        FILE="${CITELLUS_ROOT}/sos_commands/hardware/dmidecode"
    elif [[ "x$CITELLUS_LIVE" = "x1" ]];then
        FILE=$(mktemp)
        trap "rm ${FILE}" EXIT
        dmidecode > ${FILE}
    fi
    if [[ -f ${FILE} ]]; then
    (
        is_lineinfile "Product Name: VMware" "${FILE}" && echo "VMware"
        is_lineinfile "Product Name: VirtualBox" "${FILE}" && echo "Virtualbox"
        is_lineinfile "Product Name: KVM|Manufacturer: QEMU" "${FILE}" && echo "KVM"
        is_lineinfile "Product Name: Bochs" "${FILE}" && echo "Bochs"
        is_lineinfile "Product Name: RHEV Hypervisor" "${FILE}" && echo "RHEV"
    )|xargs echo
    else
        echo "Unable to determine"
    fi
}

is_virtual(){
    if [[ "x`virt_type`" -ne "x" ]] ; then
        return 1
    else
        return 0
    fi
}

