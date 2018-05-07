#!/bin/bash
# Copyright (C) 2018   Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)
#
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

# long_name: Database size
# description: Checks for mongodb database sizes
# priority: 500

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

# this can run against live or snapshot

if [[ ! "x$CITELLUS_LIVE" = "x1" ]]; then
    FILE="${CITELLUS_ROOT}/sos_commands/mongodb/du_-s_.var.lib.mongodb"
    is_required_file "${FILE}"

    # as with ONLINE, check for over 10Gb size
    LINES="$(awk '$1>10*1024*1024*1024 {print $1" "$2}' ${FILE})"

    if [[ ! -z ${LINES} ]]; then
        echo "Databases over 10gb" >&2
        awk '$1>10*1024*1024*1024 {print $1" "$2}' ${FILE} >&2
        exit ${RC_FAILED}
    else
        exit ${RC_OKAY}
    fi

else
    # This test requires mysql
    MONGODB_DIR="/var/lib/mongodb"
    if [[ -d "${MONGODB_DIR}" ]]; then
        #Db disk usage for ibdata and ib_log kinds - gb unit size kinds could be associate with perfomance degradation and a potential need of table truncate operations
        (
            du -h --threshold=10G ${MONGODB_DIR}/* | sort -nr
        )  >&2
        exit ${RC_OKAY}
    else
        echo "$MONGODB_DIR doesn't exist" >&2
        exit ${RC_FAILED}
    fi
fi

echo "Test should have skipped before reaching this point" >&2
exit ${RC_FAILED}
