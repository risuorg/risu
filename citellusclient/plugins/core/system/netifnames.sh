#!/bin/bash

# Copyright (C) 2018 Mikel Olasagasti Uranga (mikel@redhat.com)

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

# long_name: Detects if netifnames is actived on non-KVM systems
# description: Detects if net.ifnames=0 has been setup for the system. net.ifnames for RHEL7 is only supported for KVM systems. 
# priority: 500

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

ERRORMSG=$"netifnames=0 detected on non-KVM system"
ERRORMATCH="net.ifnames=0"

if [[ "x$CITELLUS_LIVE" = "x0" ]];  then
    is_required_file "${CITELLUS_ROOT}/sos_commands/kernel/dmesg"
    is_required_file "${CITELLUS_ROOT}/sos_commands/systemd/systemctl_show_--all"
    if [[ -f "${CITELLUS_ROOT}/sos_commands/networking/ip_-s_-d_link" ]]; then
        is_required_file "${CITELLUS_ROOT}/sos_commands/networking/ip_-s_-d_link"
        ip_file="${CITELLUS_ROOT}/sos_commands/networking/ip_-s_-d_link"
    else
        is_required_file "${CITELLUS_ROOT}/sos_commands/networking/ip_link"
        ip_file="${CITELLUS_ROOT}/sos_commands/networking/ip_link"
    fi

    dmesgfile="${CITELLUS_ROOT}/sos_commands/kernel/dmesg"
    virt_type=$(grep "Virtualization=" "${CITELLUS_ROOT}/sos_commands/systemd/systemctl_show_--all" |cut -d "=" -f2)
    niccount=$(grep -c "eth[0-9]" "$ip_file")

elif [[ "x$CITELLUS_LIVE" = "x1" ]]; then
    dmesgfile=$(mktemp)
    dmesg > ${dmesgfile}
    virt_type=$(systemd-detect-virt)
    niccount=$(ip l |grep -c "eth[0-9]")

    trap "rm ${dmesgfile}" EXIT
fi

if grep -q "$ERRORMATCH" "$dmesgfile"; then
    if [[ "x$virt_type" != "xkvm" ]]; then
        if ! ([ "x$niccount" = "x0" ] || [ "x$niccount" = "x1" ]); then
            echo ${ERRORMSG} >&2
            exit ${RC_FAILED}
        fi
    fi
fi

# exit as OK if haven't failed earlier
exit ${RC_OKAY}
