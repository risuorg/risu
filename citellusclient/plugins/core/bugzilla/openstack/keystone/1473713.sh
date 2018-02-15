#!/bin/bash

# Copyright (C) 2017 Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)

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

# Reference: https://bugzilla.redhat.com/show_bug.cgi?id=1473713

# long_name: Removal of expired tokens
# description: Checks for keystone transaction errors on cleanup
# bugzilla: https://bugzilla.redhat.com/show_bug.cgi?id=1473713
# priority: 600

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

is_required_file "${CITELLUS_ROOT}/var/log/keystone/keystone.log"

if is_lineinfile "ERROR keystone DBDeadlock: .*pymysql.err.Internal.* try restarting transaction.*DELETE FROM token WHERE token.expires.*" "${CITELLUS_ROOT}/var/log/keystone/keystone.log"; then
    echo $"errors on token expiration, check: https://bugzilla.redhat.com/show_bug.cgi?id=1473713" >&2
    exit ${RC_FAILED}
fi
exit ${RC_OKAY}
