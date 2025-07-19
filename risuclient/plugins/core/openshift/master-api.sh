#!/bin/bash

# Copyright (C) 2018, 2021, 2023 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

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

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

# long_name: Validate openshift-master-api requirement for openshift
# description: Validate openshift-master-api requirement for openshift
# priority: 920

# We're OCP master
if is_rpm atomic-openshift-master; then
    if is_enabled openshift-master-api; then
        if is_active openshift-master-api; then
            exit ${RC_OKAY}
        fi
    fi
    echo $"openshift-master-api service should be enabled and active" >&2
    exit ${RC_FAILED}
fi

echo $"Non Openshift master" >&2
exit ${RC_SKIPPED}
