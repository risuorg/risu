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

# we can run this against fs snapshot or live system

# long_name: Libvirt errors in nova service
# description: Report libvirtErrors in Nova OpenStack service
# priority: 800

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"


if ! is_process nova-compute; then
    echo "works only on compute node" >&2
    exit ${RC_SKIPPED}
fi

is_required_file "${CITELLUS_ROOT}/var/log/nova/nova-compute.log"
log_file="${CITELLUS_ROOT}/var/log/nova/nova-compute.log"

wc=$(grep -i 'libvirtError' ${log_file} | wc -l)
if [[ ${wc} -gt 0 ]]; then
    # to remove the ${CITELLUS_ROOT} from the stderr.
    log_file=${log_file#${CITELLUS_ROOT}}
    echo "$log_file (${wc} times)" >&2
    flag=1
fi
[[ "x$flag" = "x" ]] && exit ${RC_OKAY} || exit ${RC_FAILED}
