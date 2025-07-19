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

# long_name: Checks if sudoers misses the includedir directive and that makes fail vdsm
# description: Checks if sudoers misses the includedir directive that causes issues with vdsm and others
# priority: 400

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

# check baremetal node

journal="$journalctl_file"

if is_lineinfile "Verify sudoer rules configuration" "${journal}" "${RISU_ROOT}/var/log/messages"; then
    echo $"sudoers does miss entry for including sudoers.d folder and causes vdsm fail to start" >&2
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
