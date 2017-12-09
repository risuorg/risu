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

# we can run this against fs snapshot or live system

# description: Checks $MYSQL_HOST configuration

# Load common functions
[ -f "${CITELLUS_BASE}/common-functions.sh" ] && . "${CITELLUS_BASE}/common-functions.sh"

is_required_file "${CITELLUS_ROOT}/etc/sysconfig/clustercheck"
if is_lineinfile "^MYSQL_HOST[ \t]*=[ \t]*localhost$" "${CITELLUS_ROOT}/etc/sysconfig/clustercheck"; then
    exit $RC_OKAY
else
    echo $"clustercheck variable MYSQL_HOST should be set to localhost." >&2
    grep "^MYSQL_HOST" "${CITELLUS_ROOT}/etc/sysconfig/clustercheck" >&2
    exit $RC_FAILED
fi
