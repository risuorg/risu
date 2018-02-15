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

# long_name: NTPd time synchronization
# description: Checks for proper ntpd status
# priority: 500

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

# adapted from https://github.com/larsks/platypus/blob/master/bats/system/test_clock.bats

: ${CITELLUS_MAX_CLOCK_OFFSET:=1000}

if ! is_active ntpd;then
    echo "ntpd is not active" >&2
    exit ${RC_FAILED}
fi

is_required_file "${CITELLUS_ROOT}/etc/ntp.conf"
grep "^server" "${CITELLUS_ROOT}/etc/ntp.conf" >&2

if [[ ${CITELLUS_LIVE} = 0 ]]; then
    is_required_file "${CITELLUS_ROOT}/sos_commands/ntp/ntpq_-p"

    if grep -q "Connection refused" "${CITELLUS_ROOT}/sos_commands/ntp/ntpq_-p"; then
        echo "ntpq: read: Connection refused" >&2
        exit ${RC_FAILED}
    fi

    is_required_file "${CITELLUS_ROOT}/sos_commands/ntp/ntpq_-p"
    is_lineinfile "timed out" "${CITELLUS_ROOT}/sos_commands/ntp/ntpq_-p" && \
        echo "localhost: timed out, nothing received" >&2 && exit ${RC_FAILED}

    offset=$(awk '/^\*/ {print $9}' "${CITELLUS_ROOT}/sos_commands/ntp/ntpq_-p")
    if [[ -z "$offset" ]]; then
        echo "currently not synchronized to any clock" >&2
        candidates=$(awk '/^\+/ {print $1" ("$9"ms)"}' "${CITELLUS_ROOT}/sos_commands/ntp/ntpq_-p" | tr '\n' ' ')
        if [[ ! -z "$candidates" ]]; then
            echo "possible candidates: ${candidates}" >&2
        fi
    else
        echo "clock offset is $offset ms" >&2
        RC=$(echo "$offset<${CITELLUS_MAX_CLOCK_OFFSET:-1000} && \
            $offset>-${CITELLUS_MAX_CLOCK_OFFSET:-1000}" | bc -l)
    fi

    [[ "x$RC" = "x1" ]] && exit ${RC_OKAY} || exit ${RC_FAILED}
else
    is_required_file /usr/bin/bc

    if ! out=$(ntpq -c peers); then
        echo "failed to contact ntpd" >&2
        exit ${RC_FAILED}
    fi

    if ! awk '/^\*/ {sync=1} END {exit ! sync}' <<<"$out"; then
        echo "clock is not synchronized" >&2
        return ${RC_FAILED}
    fi

    offset=$(awk '/^\*/ {print $9}' <<<"$out")
    echo "clock offset is $offset ms" >&2

    RC=$(echo "$offset<${CITELLUS_MAX_CLOCK_OFFSET:-1000} && \
        $offset>-${CITELLUS_MAX_CLOCK_OFFSET:-1000}" | bc -l)

    [[ "x$RC" = "x1" ]] && exit ${RC_OKAY} || exit ${RC_FAILED}
fi
