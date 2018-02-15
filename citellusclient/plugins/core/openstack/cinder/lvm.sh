#!/bin/bash
# Copyright (C) 2017   Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# long_name: Cinder LVM Backend
# description: Checks if LVM is used as backing storage
# priority: 600

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

# Actually run the check
is_required_file ${CITELLUS_ROOT}/ps

if is_process nova-compute; then
    echo "works only on controller node" >&2
    exit ${RC_SKIPPED}
fi
FILE=${CITELLUS_ROOT}/etc/cinder/cinder.conf
string=volume_driver
substring=cinder.volume.drivers.lvm.LVM
RC=${RC_OKAY}

is_required_file ${FILE}

if is_lineinfile ${string} ${FILE};then
    if [[ $(grep -e ^${string} ${FILE}|cut -d "=" -f2|grep ${substring}|wc -l) -gt 0 ]]; then
        grep -e ^${string} ${FILE} >&2
        RC=${RC_FAILED}
    fi
fi

exit ${RC}
