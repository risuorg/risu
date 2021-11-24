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

# long_name: Validate etcd requirement for openshift
# description: Validate etcd requirement for openshift
# priority: 800

# We're OCP master
if is_rpm atomic-openshift-master; then
    if is_enabled etcd; then
        if is_active etcd; then
            exit ${RC_OKAY}
        fi
    fi
    echo $"etcd service should be enabled and active" >&2
    exit ${RC_FAILED}
fi

echo $"Non Openshift master" >&2
exit ${RC_SKIPPED}
