#!/bin/bash

# Copyright (C) 2018 Robin Černín <cerninr@gmail.com>
# Copyright (C) 2018, 2020, 2021 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

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

# long_name: prepares openstack version metadata
# description: Sets openstack version metadata

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

# Find release
RELEASE=$(name_osp_version)
OSPNUM=$(discover_osp_version)
if [[ ${OSPNUM} != "0" ]]; then
    echo $"${RELEASE}" >&2
    exit ${RC_OKAY}
else
    echo "Not recognized or no OSP system" >&2
    exit ${RC_SKIPPED}
fi
