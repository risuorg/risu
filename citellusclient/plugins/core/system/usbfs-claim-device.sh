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

# long_name: usbfs access to a device closure
# description: Check if applications are not closing usbfs access to a device properly
# priority: 500

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

ERRORMSG=$"App did not close properly the usbfs access to the device"
ERRORMATCH="did not claim interface"
ERRORMATCH2="usbfs"

is_required_file "${CITELLUS_ROOT}/var/log/messages"

errcount=$(zgrep "$ERRORMATCH" ${CITELLUS_ROOT}/var/log/messages* |grep "$ERRORMATCH2" |wc -l)
if [[ "x$errcount" != "x0" ]] ; then
    zgrep "$ERRORMATCH" ${CITELLUS_ROOT}/var/log/messages* |grep "$ERRORMATCH2"
    echo ${ERRORMSG} >&2
    exit ${RC_FAILED}
fi

# exit as OK if haven't failed earlier
exit ${RC_OKAY}
