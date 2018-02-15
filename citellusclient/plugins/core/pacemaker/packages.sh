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

# long_name: Outdated pacemaker packages
# description: Checks for outdated pacemaker packages
# priority: 500

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

# we can run this against fs snapshot or live system

OUTDATED=$"Outdated pacemaker packages"

PCS_VERSION=$(is_rpm pacemaker| sed -n -r -e 's/^pacemaker.*-1.1.([0-9]+)-.*$/\1/p')
if is_active pacemaker;then
    for package in ${PCS_VERSION}; do
        if [[ "${package}" -lt "15" ]]; then
            echo "$OUTDATED" >&2
            exit ${RC_FAILED}
        fi
    done
    exit ${RC_OKAY}
else
    echo "pacemaker is not running on this node" >&2
    exit ${RC_SKIPPED}
fi
