#!/bin/bash
# Copyright (C) 2021-2023 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

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

# long_name: WSGIApplicationGroup definition in mod_wsgi
# description: Checks httpd WSGIApplication defined to avoid wrong redirection
# bugzilla: https://bugzilla.redhat.com/show_bug.cgi?id=1478042
# priority: 600

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

is_required_file ${RISU_ROOT}/etc/httpd/conf.d/*-horizon_vhost.conf
if ! is_lineinfile "WSGIApplicationGroup %{GLOBAL}" ${RISU_ROOT}/etc/httpd/conf.d/*-horizon_vhost.conf; then
    echo $"https://bugzilla.redhat.com/show_bug.cgi?id=1478042" >&2
    exit ${RC_FAILED}
fi

if [[ -f "${RISU_ROOT}/var/log/httpd/horizon_error.log" ]]; then
    if is_lineinfile "End of script output before headers: django.wsgi" "${RISU_ROOT}/var/log/httpd/horizon_error.log"; then
        echo $"possible error on WSGIApplicationGroup in horizon, check: https://bugzilla.redhat.com/show_bug.cgi?id=1478042" >&2
        exit ${RC_FAILED}
    fi
fi

exit ${RC_OKAY}
