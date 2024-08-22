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

# we can run this against fs snapshot or live system

# long_name: Tooz lock errors
# description: Checks for Tooz lock error in gnocchi metrics
# priority: 600
# kb: https://access.redhat.com/solutions/3170661

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

is_required_file "${RISU_ROOT}/var/log/gnocchi/metricd.log"

if is_lineinfile "ToozError: Cannot extend an unlocked lock" "${RISU_ROOT}/var/log/gnocchi/metricd.log"; then
    if is_lineinfile "lock_timeout" "${RISU_ROOT}/etc/gnocchi/gnocchi.conf"; then
        echo $"tooz: configured lock_timeout seems not to be enough" >&2
        exit ${RC_FAILED}
    else
        echo $"tooz https://bugzilla.redhat.com/show_bug.cgi?id=1465385" >&2
        exit ${RC_FAILED}
    fi
fi

exit ${RC_OKAY}
