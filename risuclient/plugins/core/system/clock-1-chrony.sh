#!/bin/bash

# Copyright (C) 2017 Robin Černín <cerninr@gmail.com>
# Copyright (C) 2018 David Valle Delisle <dvd@redhat.com>
# Copyright (C) 2017 Lars Kellogg-Stedman <lars@redhat.com>
# Copyright (C) 2017, 2018, 2020, 2021 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

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

# long_name: Chronyd time synchronization
# description: Checks for proper chronyd status
# priority: 500

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

# adapted from https://github.com/larsks/platypus/blob/master/bats/system/test_clock.bats

: ${RISU_MAX_CLOCK_OFFSET:=1}

if ! is_active chronyd; then
    echo "chronyd is not active" >&2
    exit ${RC_FAILED}
fi

if [[ ${RISU_LIVE} == 0 ]]; then
    is_required_file ${RISU_ROOT}/sos_commands/chrony/chronyc_tracking

    if grep -q "Not synchronised\|Cannot talk to daemon" "${RISU_ROOT}/sos_commands/chrony/chronyc_tracking"; then
        echo "clock is not synchronized" >&2
        exit ${RC_FAILED}
    fi

    offset=$(awk '/RMS offset/ {print $4}' "${RISU_ROOT}/sos_commands/chrony/chronyc_tracking")
    echo "clock offset is $offset seconds" >&2

    RC=$(echo "$offset<${RISU_MAX_CLOCK_OFFSET:-1} && $offset>-${RISU_MAX_CLOCK_OFFSET:-1}" | bc -l)

else
    is_required_file /usr/bin/bc

    if ! out=$(chronyc tracking); then
        echo "clock is not synchronized" >&2
        return 1
    fi

    offset=$(awk '/RMS offset/ {print $4}' <<<"$out")
    echo "clock offset is $offset seconds" >&2

    RC=$(echo "$offset<${RISU_MAX_CLOCK_OFFSET:-1} && $offset>-${RISU_MAX_CLOCK_OFFSET:-1}" | bc -l)
fi

# Check the return code from the offset calculation
[[ "x$RC" == "x1" ]] && exit ${RC_OKAY} || exit ${RC_FAILED}
