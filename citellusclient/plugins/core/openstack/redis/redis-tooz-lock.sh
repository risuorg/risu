#!/bin/bash

# Copyright (C) 2017   Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)

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

# long_name: Tooz lock errors
# description: Checks for Tooz lock error in gnocchi metrics
# priority: 600

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

is_required_file "${CITELLUS_ROOT}/var/log/gnocchi/metricd.log"

if is_lineinfile "ToozError: Cannot extend an unlocked lock" "${CITELLUS_ROOT}/var/log/gnocchi/metricd.log"; then
    if is_lineinfile "lock_timeout" "${CITELLUS_ROOT}/etc/gnocchi/gnocchi.conf"; then
        echo $"tooz: configured lock_timeout seems not to be enough" >&2
        exit ${RC_FAILED}
    else
        echo $"tooz https://bugzilla.redhat.com/show_bug.cgi?id=1465385" >&2
        exit ${RC_FAILED}
    fi
fi

exit ${RC_OKAY}
