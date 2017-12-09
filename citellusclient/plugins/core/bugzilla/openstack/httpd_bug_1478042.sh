#!/bin/bash

# Copyright (C) 2017   David Vallee Delisle (dvd@redhat.com)

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

# description: Checks httpd WSGIApplication defined to avoid wrong redirection

# Load common functions
[ -f "${CITELLUS_BASE}/common-functions.sh" ] && . "${CITELLUS_BASE}/common-functions.sh"

is_required_file ${CITELLUS_ROOT}/etc/httpd/conf.d/*-horizon_vhost.conf
is_lineinfile "WSGIApplicationGroup %{GLOBAL}" ${CITELLUS_ROOT}/etc/httpd/conf.d/*-horizon_vhost.conf && echo $"https://bugzilla.redhat.com/show_bug.cgi?id=1478042" >&2 && exit $RC_FAILED

exit $RC_OKAY
