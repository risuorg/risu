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

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

# long_name: Heat database purge
# description: Checks if crontab for heat stack purge is in place
# priority: 700

# this can run against live and also any sort of snapshot of the filesystem

is_required_file "${CITELLUS_ROOT}/var/spool/cron/heat"
if ! awk '/heat-manage purge_deleted/ && /^[^#]/ { print $0 }' "${CITELLUS_ROOT}/var/spool/cron/heat" > /dev/null 2>&1; then
    echo $"crontab heat stack purge is not set" >&2
    exit ${RC_FAILED}
elif awk '/heat-manage purge_deleted/ && /^[^#]/ { print $0 }' "${CITELLUS_ROOT}/var/spool/cron/heat" > /dev/null 2>&1; then
    exit ${RC_OKAY}
fi
