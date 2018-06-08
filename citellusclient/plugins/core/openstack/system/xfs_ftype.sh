#!/bin/bash
# Copyright (C) 2018 Pablo Iranzo Gómez <Pablo.Iranzo@redhat.com>
# Copyright (C) 2018 Mikel Olasagasti Uranga <mikel@redhat.com>

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

# long_name: Check if XFS FS is compatibly with Docker for +OSP12
# description: Checks if XFS that contains /var/lib is able to run overlayFS
# priority: 700
# bugzilla: 1575115

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

#is_required_file ${CITELLUS_BASE}/etc/redhat-release
RELEASE=$(discover_rhrelease)

[[ "${RELEASE}" -eq '0' ]] && echo "RH release undefined" >&2 && exit ${RC_SKIPPED}

if [[ ${CITELLUS_LIVE} -eq 0 ]]; then
    if [[ -f "${CITELLUS_ROOT}/sos_commands/xfs/xfs_info_.var.lib" ]]; then
        FILE="${CITELLUS_ROOT}/sos_commands/xfs/xfs_info_.var.lib"
    elif [[ -f "${CITELLUS_ROOT}/sos_commands/xfs/xfs_info_.var" ]]; then
        FILE="${CITELLUS_ROOT}/sos_commands/xfs/xfs_info_.var"
    elif [[ -f "${CITELLUS_ROOT}/sos_commands/xfs/xfs_info" ]]; then
        FILE="${CITELLUS_ROOT}/sos_commands/xfs/xfs_info"
    else
        exit ${RC_SKIPPED}
    fi
elif [[ ${CITELLUS_LIVE} -eq 1 ]];then
    FILE=$(mktemp)
    trap "rm ${FILE}" EXIT
    xfs_info /var/lib > ${FILE}
fi

if is_lineinfile "ftype=0" "${FILE}"; then
    echo $"Node not supported for OSP13 - Can't use containers" >&2
    exit ${RC_FAILED}
fi

exit ${RC_OKAY}


