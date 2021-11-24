#!/bin/bash

# Copyright (C) 2018, 2021 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

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

# long_name: Checks dc-version in pacemaker
# description: Reports dc-version in pacemaker cluster
# path: Pacemaker-dc-version
# priority: 900

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

if [[ ${RISU_LIVE} -eq "1" ]]; then
    is_required_command pcs
    pcs property list --all | grep dc-version >&2
else
    is_required_file "${RISU_ROOT}/sos_commands/pacemaker/pcs_property_list_--all"
    grep dc-version "${RISU_ROOT}/sos_commands/pacemaker/pcs_property_list_--all" >&2
fi

exit ${RC_OKAY}
