#!/bin/bash

# Copyright (C) 2018 Mikel Olasagasti Uranga (mikel@redhat.com)

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

# long_name: soft lockup with _raw_spin_lock in ovs_flow_stats_update 
# description: A deadlock could occur when the system attempts to read ovs flow stats 
# bugzilla: https://bugzilla.redhat.com/show_bug.cgi?id=1094867
# priority: 100

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

ERRORMSG=$"soft lockup with _raw_spin_lock in ovs_flow_stats_update"
ERRORMATCH1="BUG: soft lockup"
ERRORMATCH2="_raw_spin_lock"
ERRORMATCH3="ovs_flow_stats_update"

is_required_file "${CITELLUS_ROOT}/var/log/messages"

errcount=$(zgrep "$ERRORMATCH1" ${CITELLUS_ROOT}/var/log/messages* |wc -l)
if [[ "x$errcount" != "x0" ]] ; then
    errcount2=$(zgrep "$ERRORMATCH2" ${CITELLUS_ROOT}/var/log/messages* |wc -l)
    errcount3=$(zgrep "$ERRORMATCH3" ${CITELLUS_ROOT}/var/log/messages* |wc -l)
    if [[ "x$errcount2" != "x0" ]] || [[ "x$errcount3" != "x0" ]] ; then
        echo ${ERRORMSG} >&2
        exit ${RC_FAILED}
    fi
fi

exit ${RC_OKAY}
