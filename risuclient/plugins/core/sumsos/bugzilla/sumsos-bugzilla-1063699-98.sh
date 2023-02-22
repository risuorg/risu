#!/bin/bash

# Copyright (C) 2017 Robin Černín <cerninr@gmail.com>
# Copyright (C) 2018, 2021, 2022 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

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

# long_name: Finds matches of kernel: BUG: soft lockup - CPU#.* stuck for .*s! \[(lpfc_worker_|fc_dl_)
# description: Finds matches of error kernel: BUG: soft lockup - CPU#.* stuck for .*s! \[(lpfc_worker_|fc_dl_)

# bugzilla: https://bugzilla.redhat.com/show_bug.cgi?id=1063699
REGEXP="kernel: BUG: soft lockup - CPU#.* stuck for .*s! \[(lpfc_worker_|fc_dl_)"
BZ=1063699

# priority: 500

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

journal="$journalctl_file"

if is_lineinfile "${REGEXP}" ${journal} ${RISU_ROOT}/var/log/messages; then
    echo $"Check bugzilla: https://bugzilla.redhat.com/show_bug.cgi?id=$BZ for more details about error: $REGEXP found in logs" >&2
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
