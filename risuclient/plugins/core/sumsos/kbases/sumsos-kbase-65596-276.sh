#!/bin/bash

# Copyright (C) 2021-2023 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

# Code based on the regexps from sumsos from John Devereux (john_devereux@yahoo.com)

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

# long_name: Finds matches of kernel:.*rport-.*: blocked FC remote port time out: removing rport
# description: Finds matches of error kernel:.*rport-.*: blocked FC remote port time out: removing rport

REGEXP="kernel:.*rport-.*: blocked FC remote port time out: removing rport"
KCS=65596

# priority: 400

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

journal="$journalctl_file"

if is_lineinfile "${REGEXP}" ${journal} ${RISU_ROOT}/var/log/messages; then
    echo $"Check Kbase: https://access.redhat.com/solutions/$KCS for more details about error: $REGEXP found in logs" >&2
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi

# kb: https://access.redhat.com/solutions/65596
