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

# this can run against live and also any sort of snapshot of the filesystem

# long_name: Keystone clean-up frequency
# description: Keystone cleanups might not be frequent enough on busy systems, check frequency
# priority: 700

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

# Find release to report which bug to check
RELEASE=$(discover_osp_version)

is_required_file "${CITELLUS_ROOT}/var/spool/cron/keystone"

if ! awk '/keystone-manage token_flush/ && /^[^#]/ { print $0 }' "${CITELLUS_ROOT}/var/spool/cron/keystone" >/dev/null 2>&1; then
    echo $"crontab keystone cleanup is not set" >&2
    exit ${RC_FAILED}
elif awk '/keystone-manage token_flush/ && /^[^#]/ { print $0 }' "${CITELLUS_ROOT}/var/spool/cron/keystone" >/dev/null 2>&1; then
    # Skip default crontab of 1 0 * * * as it might miss busy systems and fail to do later cleanups
    COUNT=$(awk '/keystone-manage token_flush/ && /^[^#]/ { print $0 }' "${CITELLUS_ROOT}/var/spool/cron/keystone" 2>&1|egrep  '^1 0'  -c)
    if [[ "x$COUNT" = "x1" ]]; then
        echo -n $"token flush not running every hour " >&2
        case ${RELEASE} in
            6) echo "https://bugzilla.redhat.com/show_bug.cgi?id=1470230" >&2 ;;
            7) echo "https://bugzilla.redhat.com/show_bug.cgi?id=1470227" >&2 ;;
            8) echo "https://bugzilla.redhat.com/show_bug.cgi?id=1470226" >&2 ;;
            9) echo "https://bugzilla.redhat.com/show_bug.cgi?id=1470221" >&2 ;;
            10) echo "https://bugzilla.redhat.com/show_bug.cgi?id=1469457" >&2 ;;
            *) echo "" >&2 ;;
        esac
        exit ${RC_FAILED}
    fi
    exit ${RC_OKAY}
fi
