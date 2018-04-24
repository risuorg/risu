#!/bin/bash

# Copyright (C) 2018   Benoit Welterlen (bwelterl@redhat.com)

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

# long_name: non ASCII characters in limits.conf file make it useless
# description: Looks for non ASCII characters in limits.conf
# priority: 400

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

REGEXP="systemd\[[0-9]+\]: Cannot add dependency job for unit ([^,]+), ignoring: Unit not found."

#if [[ "x$CITELLUS_LIVE" = "x0" ]]; then
is_required_file "${CITELLUS_ROOT}/etc/security/limits.conf"

bad_files=`grep -s -l -P -n "[\x80-\xFF]" ${CITELLUS_ROOT}/etc/security/limits.conf ${CITELLUS_ROOT}/etc/security/limits.d/*.conf`
if [[ -n "$bad_files" ]]; then
    for f in ${bad_files}; do
        echo "file $f contains non ASCII characters." >&2
    done
    echo "This makes the system to ignore it." >&2
    exit ${RC_FAILED}
fi

# If the above conditions did not trigger RC_FAILED we are good.
exit ${RC_OKAY}
