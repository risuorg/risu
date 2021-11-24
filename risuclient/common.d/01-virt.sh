#!/usr/bin/env bash
# Description: This script contains common functions to be used by risu plugins
#
# Copyright (C) 2018 Mikel Olasagasti Uranga <mikel@olasagasti.info>
# Copyright (C) 2018, 2020, 2021 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>
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

virt_type() {
    if [[ "x$RISU_LIVE" == "x0" ]]; then
        FILE="${RISU_ROOT}/sos_commands/hardware/dmidecode"
    elif [[ "x$RISU_LIVE" == "x1" ]]; then
        FILE=$(mktemp)
        trap "rm ${FILE}" EXIT
        dmidecode >${FILE}
    fi
    if [[ -f ${FILE} ]]; then
        (
            is_lineinfile "Product Name: VMware" "${FILE}" && echo "VMware"
            is_lineinfile "Product Name: VirtualBox" "${FILE}" && echo "Virtualbox"
            is_lineinfile "Product Name: KVM|Manufacturer: QEMU" "${FILE}" && echo "KVM"
            is_lineinfile "Product Name: Bochs" "${FILE}" && echo "Bochs"
            is_lineinfile "Product Name: RHEV Hypervisor" "${FILE}" && echo "RHEV"
            is_lineinfile "Product Name: OpenStack Compute" "${FILE}" && echo "OpenStack"
            is_lineinfile "Product Name: OpenStack Nova" "${FILE}" && echo "OpenStack"
            is_lineinfile "Product Name: Google Compute Engine" "${FILE}" && echo "Google Compute Engine"
            is_lineinfile "Product Name: AHV" "${FILE}" && echo "Nutanix AHV"
            is_lineinfile "Manufacturer: DigitalOcean" "${FILE}" && echo "DigitalOcean"
            uuid=$(python ${RISU_BASE}/tools/dmidecode.py <${FILE} | grep UUID | awk '{print $7}' | sed 's/)//')
            amazon=$(python ${RISU_BASE}/tools/dmidecode.py <${FILE} | grep -c amazon)
            if [[ $(echo ${uuid} | grep -c ^EC2) -eq 1 ]] || [[ ${amazon} -gt 0 ]]; then
                echo "AWS"
            fi

            azure=$(grep -A2 "Manufacturer: Microsoft Corporation" "${FILE}" | grep -A1 "Product Name: Virtual Machine" | grep "Version: 7.0" -c)
            if [[ ${azure} -gt 0 ]]; then
                echo "Azure"
            fi

            hyperv=$(grep -A2 "Manufacturer: Microsoft Corporation" "${FILE}" | grep -A1 "Product Name: Virtual Machine" | grep "Version: Hyper-V" -c)
            if [[ ${hyperv} -gt 0 ]]; then
                echo "Hyper-V"
            fi

        ) | xargs echo
    else
        echo "Unable to determine"
    fi
}

is_virtual() {
    if [[ "$(virt_type)" == "" ]]; then
        return 1
    else
        return 0
    fi
}
