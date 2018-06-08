#!/bin/bash

# Copyright (C) 2018 Pablo Iranzo Gómez <Pablo.Iranzo@redhat.com>


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

# long_name: Checks if RRNG is enabled for vm's
# description: Reports vm's with NOT enabled RRNG
# priority: 100

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

# check VM
flag=1 # We're baremetal, so we exit

if ! is_virtual ; then
    echo "Not running on a VM" >&2
    exit ${RC_SKIPPED}
fi

if ! is_pkg rng-tools; then
    echo $"rng-tools not installed on a VM, Random number requiring apps will stall until enough entropy is generated" >&2
    exit ${RC_FAILED}
fi

if ! is_active rngd; then
    echo "$rngd should be active for seeding entropy pool" >&2
    exit ${RC_FAILED}
fi

exit ${RC_OKAY}

