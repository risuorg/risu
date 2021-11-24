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

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

# long_name: Validate Docker requirement for openshift
# description: Validate Docker requirement for openshift
# priority: 800

# We're OCP node
if is_rpm atomic-openshift-node; then
    if is_rpm docker; then
        if is_enabled docker; then
            if is_active docker; then
                exit ${RC_OKAY}
            fi
        fi
        echo $"Docker service should be enabled and active" >&2
        exit ${RC_FAILED}
    else
        echo $"Docker service should be installed" >&2
        exit ${RC_FAILED}
    fi
fi
echo $"Non Openshift node" >&2
exit ${RC_SKIPPED}
