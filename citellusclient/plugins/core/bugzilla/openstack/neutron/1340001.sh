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

# long_name: Keystone metadata_agent.ini misconfiguration
# description: Checks for wrong auth_url configuration in metadata_agent.ini
# bugzilla: https://bugzilla.redhat.com/show_bug.cgi?id=1340001
# priority: 600

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

RELEASE=$(discover_osp_version)

if [[ "${RELEASE}" -le "8" ]]; then
    is_required_file "${CITELLUS_ROOT}/etc/neutron/metadata_agent.ini"

    if ! is_lineinfile "auth_url.*/v(2.0|3)" "${CITELLUS_ROOT}/etc/neutron/metadata_agent.ini"; then
        echo $"keystone auth_url set wrongly in metadata_agent.ini https://bugzilla.redhat.com/show_bug.cgi?id=1340001" >&2
        exit ${RC_FAILED}
    else
        exit ${RC_OKAY}
    fi
else
    echo "works only on OSP8 and earlier" >&2
    exit ${RC_SKIPPED}
fi
