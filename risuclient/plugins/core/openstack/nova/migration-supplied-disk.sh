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

# long_name: Check for nova error on migration because of existing disk
# description: Check for nova error on migration because of existing disk
# priority: 750
# kb: https://access.redhat.com/solutions/1597443

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

is_required_file "${RISU_ROOT}/var/log/nova/nova-compute.log"

if is_lineinfile "DestinationDiskExists: The supplied disk path .* already exists, it is expected not to exist." "${RISU_ROOT}/var/log/nova/nova-compute.log"; then
    echo $"nova supplied disk exists" >&2
    exit ${RC_FAILED}
fi

exit ${RC_OKAY}
