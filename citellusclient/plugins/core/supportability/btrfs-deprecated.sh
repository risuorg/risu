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

# long_name: Reports if BTRFS is used as it is deprecated for +RHEL-7.5
# description: Checks if any BTRFS filesystem is mounted as BTRFS is deprecated since +RHEL-7.5
# priority: 1

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

#is_required_file ${CITELLUS_BASE}/etc/redhat-release
RELEASE=$(discover_rhrelease)

[[ "${RELEASE}" -eq '0' ]] && echo "RH release undefined" >&2 && exit ${RC_SKIPPED}

if [[ ${RELEASE} -gt 7 ]]; then
    echo "test not applicable to EL8 releases or higher" >&2
    exit ${RC_SKIPPED}
fi

if [[ ${CITELLUS_LIVE} -eq 0 ]]; then
    FILE="${CITELLUS_ROOT}/proc/mounts"
elif [[ ${CITELLUS_LIVE} -eq 1 ]];then
    FILE=$(mktemp)
    trap "rm ${FILE}" EXIT
    cat /proc/mounts > ${FILE}
fi

if is_lineinfile "btrfs" "${FILE}"; then
    echo $"Check RHEL7.5 BTRFS deprecation" >&2
    exit ${RC_INFO}
fi

exit ${RC_OKAY}

