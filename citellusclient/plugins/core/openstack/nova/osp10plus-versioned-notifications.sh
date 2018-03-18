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

# long_name: Nova unversioned notifications
# description: Checks if nova on OSP11 is using only unversioned notifications
# priority: 600

# Reference: https://bugzilla.redhat.com/show_bug.cgi?id=1478274


# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

is_required_file "${CITELLUS_ROOT}/etc/nova/nova.conf"

if [[ "$(discover_osp_version)" -lt "10" ]]; then
    echo "works only on OSP 10+" >&2
    exit ${RC_SKIPPED}
elif [[ "$(discover_osp_version)" -eq "10" ]]; then
    conf_section="DEFAULT"
else
    conf_section="notifications"
fi

if [[ "$(iniparser "${CITELLUS_ROOT}/etc/nova/nova.conf" ${conf_section} notification_format)" == "unversioned" ]]; then
    exit ${RC_OKAY}
else
    echo $"missing notification_format=unversioned in nova.conf" >&2
    echo $"Check: https://bugzilla.redhat.com/show_bug.cgi?id=1478274" >&2
    exit ${RC_FAILED}
fi
