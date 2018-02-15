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

# long_name: Keystone token clean-up runs
# description: Checks for token cleanup expired tokens removal
# priority: 600

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

RUNS=$(grep 'Total expired tokens removed' "${CITELLUS_ROOT}/var/log/keystone/keystone.log" | wc -l)

[[ "x${RUNS}" = "x" ]] && echo "Non recorded cleanup runs" >&2 && exit ${RC_FAILED}

if [[ "${RUNS}" -eq 0 ]]; then
    echo "Non recorded cleanup runs" >&2
    exit ${RC_FAILED}
elif [[ "${RUNS}" -ge 1 ]]; then
    echo "${RUNS}" >&2
    exit ${RC_OKAY}
fi
