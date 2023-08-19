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

# long_name: Detects journal corrupted journal
# description: Detects corrupted journal file on disk
# priority: 700

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

if [[ "x$RISU_LIVE" == "x0" ]]; then
    is_required_file "${RISU_ROOT}/sos_commands/kernel/dmesg"
    if is_lineinfile "/var/log/journal/.*/system.journal corrupted or uncleanly shut down" "${RISU_ROOT}/sos_commands/kernel/dmesg"; then
        echo "corrupted journal detected" >&2
        exit ${RC_FAILED}
    fi
elif [[ "x$RISU_LIVE" == "x1" ]]; then
    if dmesg | grep -eq "/var/log/journal/.*/system.journal corrupted or uncleanly shut down"; then
        echo "corrupted journal detected" >&2
        exit ${RC_FAILED}
    fi
fi

# exit as OK if haven't failed earlier
exit ${RC_OKAY}
