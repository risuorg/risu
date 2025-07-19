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

# long_name: Detects packet drops when ip_conntrack or nf_conntrack tables are full
# description: Detects packet drops when using ip_conntrack or nf_conntrack, logs say 'ip_conntrack: table full, dropping packet.' or 'nf_conntrack: table full, dropping packet'
# priority: 400
# kb: https://access.redhat.com/solutions/8721

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

ERRORMSG=$"packet drop because ip/nf_conntrack tables are full detected"

if [[ "x$RISU_LIVE" == "x0" ]]; then
    is_required_file "${RISU_ROOT}/sos_commands/kernel/dmesg"
    if is_lineinfile "table full, dropping packet" "${RISU_ROOT}/sos_commands/kernel/dmesg"; then
        echo ${ERRORMSG} >&2
        exit ${RC_FAILED}
    fi
elif [[ "x$RISU_LIVE" == "x1" ]]; then
    if dmesg | grep -eq "table full, dropping packet"; then
        echo ${ERRORMSG} >&2
        exit ${RC_FAILED}
    fi
fi

# exit as OK if haven't failed earlier
exit ${RC_OKAY}
