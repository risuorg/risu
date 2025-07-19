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

# this can run against live and also any sort of snapshot of the filesystem

# long_name: Detects attempts to live migrate cinder volumes without being supported
# description: Checks errors on nova migration with attached volumes
# bugzilla: https://bugzilla.redhat.com/show_bug.cgi?id=1498831
# priority: 750
# kb: https://access.redhat.com/solutions/2451541

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

is_required_file "${RISU_ROOT}/var/log/messages"

# Find release
RELEASE=$(discover_osp_version)

if [[ ${RELEASE} -lt "9" ]]; then
    if is_lineinfile 'MigrationError_Remote: Migration error: Cannot block migrate instance' "${RISU_ROOT}/var/log/messages"; then
        echo $"Block migration unavailable before Mitaka" >&2
        exit ${RC_FAILED}
    fi
    exit ${RC_OKAY}
else
    exit ${RC_OKAY}
fi
