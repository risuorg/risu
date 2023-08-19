#!/bin/bash

# Copyright (C) 2023 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

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

# long_name: Reports if system is using dnf or yum's versionlock as it might cause missing upgrades
# description: Reports if system is using dnf or yum's versionlock as it might cause missing upgrades
# priority: 100
# kb:

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

is_required_file ${RISU_ROOT}/etc/dnf/plugins/versionlock.list

LINES=$(cat ${RISU_ROOT}/etc/dnf/plugins/versionlock.list | wc -l)

if [[ ${LINES} -eq "0" ]]; then
    exit ${RC_OKAY}
else

    echo "System has contents in YUM/DNF versionlock, check for possible missing package updates" >&2
    exit ${RC_INFO}

fi
