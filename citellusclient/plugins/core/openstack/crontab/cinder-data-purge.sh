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

# long_name: Cinder database purge
# description: Checks if crontab for cinder data purge is in place
# priority: 700

# this can run against live and also any sort of snapshot of the filesystem

is_required_file "${CITELLUS_ROOT}/var/spool/cron/cinder"
if ! awk '/cinder-manage db purge 30/ && /^[^#]/ { print $0 }' "${CITELLUS_ROOT}/var/spool/cron/cinder" > /dev/null 2>&1; then
    echo $"crontab cinder db purge is not set" >&2
    exit ${RC_FAILED}
elif awk '/cinder-manage db purge 30/ && /^[^#]/ { print $0 }' "${CITELLUS_ROOT}/var/spool/cron/cinder" > /dev/null 2>&1; then
    exit ${RC_OKAY}
fi
