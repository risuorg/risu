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

# long_name: returns the role of the system (master, node, etc)
# description: This plugin is used in various functions. It's just a metadata plugin.
# priority: 0

# Load common functions
[ -f "${RISU_BASE}/common-functions.sh" ] && . "${RISU_BASE}/common-functions.sh"

if is_rpm atomic-openshift-master; then
    ROLE='master'
elif [[ -f ${RISU_ROOT}/etc/origin/master/master-config.yaml ]]; then
    ROLE='master'
elif is_rpm atomic-openshift-node; then
    ROLE='node'
else
    echo "Couldn't determine OCP role" >&2
    ROLE='unknown'
    exit ${RC_SKIPPED}
fi

echo ${ROLE} >&2
exit ${RC_OKAY}
