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

# long_name: Finds matches of kernel.*cifs_mount failed w/return code = -95
# description: Finds matches of error kernel.*cifs_mount failed w/return code = -95

REGEXP="kernel.*cifs_mount failed w/return code = -95"

# priority: 700

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

journal="$journalctl_file"

if is_lineinfile "${REGEXP}" ${journal} ${RISU_ROOT}/var/log/messages; then
    echo $"CIFS: mount error(95): Operation not supported." >&2
    echo $"$REGEXP found in logs" >&2
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
