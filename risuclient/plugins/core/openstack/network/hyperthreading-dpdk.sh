#!/bin/bash
# Copyright (C) 2021-2023 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

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

# long_name: Check HyperThreading and DPDK Network
# description: Checks if HT and DPDK network are enabled
# priority: 870

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

is_required_file "${RISU_ROOT}"/etc/nova/nova.conf
is_required_file "${RISU_ROOT}"/proc/cpuinfo

if [[ ${RISU_LIVE} -eq 0 ]]; then
    FILE="${RISU_ROOT}/sos_commands/openvswitch/ovs-vsctl_-t_5_get_Open_vSwitch_._other_config"
elif [[ ${RISU_LIVE} -eq 1 ]]; then
    FILE=$(mktemp)
    trap "rm ${FILE}" EXIT
    ovs-vsctl -t 5 get Open_vSwitch . other_config >${FILE}
fi

is_required_file "${FILE}"

if is_lineinfile "dpdk-init.*true" "${FILE}"; then
    if ! is_lineinfile '^flags\b.*: .*\bht\b' "${RISU_ROOT}"/proc/cpuinfo; then
        # HT is NOT enabled
        echo $"Hyperthreading not enabled in DPDK host" >&2
        exit ${RC_FAILED}
    fi
fi

exit ${RC_OKAY}
