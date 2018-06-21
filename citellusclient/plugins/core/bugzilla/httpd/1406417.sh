#!/bin/bash
# Copyright (C) 2018 David Valle Delisle <dvd@redhat.com>
# Copyright (C) 2017, 2018 Robin Černín <cerninr@gmail.com>
# Copyright (C) 2017, 2018 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

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

# long_name: MaxRequestWorkers limits
# description: This plugin checks if Apache reaches its MaxRequestWorkers
# bugzilla: https://bugzilla.redhat.com/show_bug.cgi?id=1406417
# priority: 800

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

is_required_file "${CITELLUS_ROOT}/var/log/httpd/error_log"
is_required_pkg openstack-gnocchi-common

is_lineinfile "MaxRequestWorkers" "${CITELLUS_ROOT}/var/log/httpd/error_log" && echo $"https://bugzilla.redhat.com/show_bug.cgi?id=1406417" >&2 && exit ${RC_FAILED}

exit ${RC_OKAY}

