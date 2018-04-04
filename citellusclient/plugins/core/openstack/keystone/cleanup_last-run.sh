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

# long_name: Keystone token clean-up last execution date
# description: Checks for token cleanup last execution
# priority: 900

# this can run against live and also fs snapshot

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

is_required_file "${CITELLUS_ROOT}/var/log/keystone/keystone.log"

# Check if we've the keystone token manage cleanup job so we asume it's controller
is_required_file "${CITELLUS_ROOT}/var/spool/cron/keystone"
if ! is_lineinfile keystone-manage "${CITELLUS_ROOT}/var/spool/cron/keystone"; then
    echo "Only runs on OSP controller" >&2
    exit ${RC_SKIPPED}
fi

if [[ "${CITELLUS_LIVE}" = "1" ]]; then
    NOW=$(date)
else
    is_required_file "${CITELLUS_ROOT}/date"
    NOW="$(cat ${CITELLUS_ROOT}/date)"
fi

LASTRUN=$(grep 'Total expired tokens removed' "${CITELLUS_ROOT}/var/log/keystone/keystone.log"|awk '/Total expired tokens removed/ { print $1 " " $2 }' | tail -1)
if [[ "x${LASTRUN}" = "x" ]];then
    echo "no recorded last run of token removal" >&2
    exit ${RC_FAILED}
else
    # Not just last run, but we also want it to be 'recent'
    if are_dates_diff_over 2 "$NOW" "$LASTRUN"; then
        echo $"Last token run was more than two days ago" >&2
        exit ${RC_FAILED}
    fi
    echo "${LASTRUN}" >&2
    exit ${RC_OKAY}
fi
