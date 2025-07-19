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

# if we are running against fs snapshot we check installed-rpms

# long_name: Packstack installation
# description: Report OSP version
# priority: 750

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

# Check which version we are using
PACKSTACK=$(is_rpm "openstack-packstack")
if [[ -n ${PACKSTACK} ]]; then
    echo $"packstack detected" >&2
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
