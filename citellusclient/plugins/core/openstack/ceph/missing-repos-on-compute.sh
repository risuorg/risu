#!/bin/bash
#
# Copyright (C) 2017  Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# long_name: Ceph rhceph repository
# description: Checks if Ceph repos are not enabled on computes
# priority: 200

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

# check if we are running against compute

if ! is_process nova-compute; then
    echo "works only on compute node" >&2
    exit ${RC_SKIPPED}
fi
OUTDATED=$"librbd1 might be outdated if rhceph repo is not enabled on compute"

if [[ "x$CITELLUS_LIVE" = "x1" ]]; then
    if [[ "$(yum -C repolist 2>&1 | grep "rhceph.*tools" | wc -l)" -eq "0" ]]; then
        echo "$OUTDATED" >&2
        exit ${RC_FAILED}
    else
        exit ${RC_OKAY}
    fi
elif [[ "x$CITELLUS_LIVE" = "x0" ]]; then
    if [[ "$(cat ${CITELLUS_ROOT}/sos_commands/yum/yum_-C_repolist | grep "rhceph.*tools" | wc -l)" -eq "0" ]]; then
        echo "$OUTDATED" >&2
        exit ${RC_FAILED}
    else
        exit ${RC_OKAY}
    fi
fi
