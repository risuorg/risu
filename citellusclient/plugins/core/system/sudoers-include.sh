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

# long_name: Checks if sudoers misses the includedir directive
# description: Checks if sudoers misses the includedir directive that causes issues with vdsm and others
# priority: 800

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

# check baremetal node

is_required_file "${CITELLUS_ROOT}/etc/sudoers"

if ! is_lineinfile "^#includedir /etc/sudoers.d" "${CITELLUS_ROOT}/etc/sudoers"; then
    echo $"sudoers does miss entry for including sudoers.d folder" >&2
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
