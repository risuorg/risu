#!/bin/bash

# Copyright (C) 2017 Robin Černín (rcernin@redhat.com)
# Modifications by Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)

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

# adapted from https://github.com/larsks/platypus/blob/master/bats/system/test_clock.bats

# long_name: Chronyd configuration in OSP
# description: Reports if chrony is used on an OpenStack node
# priority: 400

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

(
if is_active chronyd; then
    chronyd=1
fi
) >/dev/null 2>&1

if is_rpm openstack-.*  > /dev/null 2>&1; then
    # Node is OSP system
    if [[ "x$chronyd" = "x1" ]]; then
        echo $"chrony service is active, and it should not on OSP node" >&2
        exit ${RC_FAILED}
    else
        exit ${RC_OKAY}
    fi
else
    echo "works only on osp node" >&2
    exit ${RC_SKIPPED}
fi
