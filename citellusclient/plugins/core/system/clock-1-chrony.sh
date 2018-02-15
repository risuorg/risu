#!/bin/bash

# Copyright (C) 2017   Robin Černín (rcernin@redhat.com)

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
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

# adapted from https://github.com/larsks/platypus/blob/master/bats/system/test_clock.bats

: ${CITELLUS_MAX_CLOCK_OFFSET:=1}

if ! is_active chronyd;then
    echo "chronyd is not active" >&2
    exit ${RC_FAILED}
fi

if [[ ${CITELLUS_LIVE} = 0 ]]; then
    is_required_file ${CITELLUS_ROOT}/sos_commands/chrony/chronyc_tracking

    if grep -q "Not synchronised\|Cannot talk to daemon" "${CITELLUS_ROOT}/sos_commands/chrony/chronyc_tracking"; then
        echo "clock is not synchronized" >&2
        exit ${RC_FAILED}
    fi

    offset=$(awk '/RMS offset/ {print $4}' "${CITELLUS_ROOT}/sos_commands/chrony/chronyc_tracking")
    echo "clock offset is $offset seconds" >&2

    RC=$(echo "$offset<${CITELLUS_MAX_CLOCK_OFFSET:-1} && \
    $offset>-${CITELLUS_MAX_CLOCK_OFFSET:-1}" | bc -l)

else
    is_required_file /usr/bin/bc

    if ! out=$(chronyc tracking); then
        echo "clock is not synchronized" >&2
        return 1
    fi

    offset=$(awk '/RMS offset/ {print $4}' <<<"$out")
    echo "clock offset is $offset seconds" >&2

    RC=$(echo "$offset<${CITELLUS_MAX_CLOCK_OFFSET:-1} && $offset>-${CITELLUS_MAX_CLOCK_OFFSET:-1}" | bc -l)
fi

# Check the return code from the offset calculation
[[ "x$RC" = "x1" ]] && exit ${RC_OKAY} || exit ${RC_FAILED}
