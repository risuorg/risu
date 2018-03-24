#!/bin/bash

# Copyright (C) 2018 Juan Luis de Sousa-Valadas (jdesousa@redhat.com)

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

# we can run this on fs snapshot or live system

# long_name: Verify OpenShift Nodes have NetworkManager enabled
# description: With OpenShift Nodes NetworkManager is required
# priority: 700

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

if is_enabled atomic-openshift-node ; then
    if is_enabled ^NetworkManager.service; then
        echo 'OpenShift and NetworkManager are both enabled' >&2
        exit ${RC_OKAY}
    else
        echo 'OpenShift nodes require NetworkManager to be enabled' >&2
        exit ${RC_FAILED}
    fi
else
    echo 'atomic-openshift-node is not enabled' >&2
    exit ${RC_SKIPPED}
fi

