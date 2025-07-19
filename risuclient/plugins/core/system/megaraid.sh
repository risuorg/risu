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

# long_name: Detects PERC RAID / Megaraid resets
# description: Detects if PERC RAID Controller or Linux Megaraid Driver resets resulting in intermittent loss of access to all drivers on system
# priority: 400
# kb: https://access.redhat.com/solutions/3010132

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

ERRORMSG=$"PERC RAID / Megaraid reset detected"
ERRORMATCH="megaraid_sas: resetting fusion adapter"

is_required_file "${RISU_ROOT}/var/log/messages"

errcount=$(zgrep "$ERRORMATCH" ${RISU_ROOT}/var/log/messages* | wc -l)
if [[ "x$errcount" != "x0" ]]; then
    echo ${ERRORMSG} >&2
    exit ${RC_FAILED}
fi

# exit as OK if haven't failed earlier
exit ${RC_OKAY}
