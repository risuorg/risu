#!/bin/bash

# Copyright (C) 2018   Robin Černín (rcernin@redhat.com)

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

# Reference: https://bugzilla.redhat.com/show_bug.cgi?id=1478042

# long_name: Missing WSGIApplicationGroup
# description: Checks for missing WSGIApplicationGroup in horizon
# bugzilla: https://bugzilla.redhat.com/show_bug.cgi?id=1478042
# priority: 800

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

is_required_file "${CITELLUS_ROOT}/var/log/httpd/horizon_error.log"

if is_lineinfile "End of script output before headers: django.wsgi" "${CITELLUS_ROOT}/var/log/httpd/horizon_error.log"; then
    echo $"errors on WSGIApplicationGroup in horizon, check: https://bugzilla.redhat.com/show_bug.cgi?id=1478042" >&2
    exit $RC_FAILED
fi
exit $RC_OKAY
