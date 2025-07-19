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

# long_name: Checks for DPDK network memory pages
# description: Checks for configured dpdk network pages in nova
# priority: 930
# kb: https://access.redhat.com/solutions/3250441

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

is_required_file "${RISU_ROOT}/var/log/messages"
is_required_file "${RISU_ROOT}/etc/nova/nova.conf"

# Now check if we've the error message in logs:
if is_lineinfile "Insufficient free host memory pages available to allocate guest RAM" "${RISU_ROOT}/var/log/messages"; then
    if ! is_lineinfile "reserved_huge_pages.*None" "${RISU_ROOT}/var/log/nova/nova-compute.log"; then
        exit ${RC_OKAY}
    fi
    RELEASE=$(discover_osp_version)
    if [[ $RELEASE -ge 10 ]]; then
        echo $"your system might have to set reserved_huge_pages for DPDK environments to be able to correctly calculate available Hugepages" >&2
        exit ${RC_FAILED}
    fi
fi
exit ${RC_OKAY}
