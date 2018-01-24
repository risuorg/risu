#!/bin/bash

# Copyright (C) 2018 Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)

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

# long_name: Checks if kernel has been tainted and reports value
# description: Checks kernel taint value
# priority: 100

# Load common functions
[[ -f -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

# we can run this against fs snapshot or live system

TAINT=$(cat ${CITELLUS_ROOT}/proc/sys/kernel/tainted)

if [[ "x$TAINT" = "x0" ]]; then
    exit $RC_OKAY
else
    echo $"Kernel is tainted" $TAINT
    exit $RC_FAILED
fi
