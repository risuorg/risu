#!/bin/bash
# Copyright (C) 2018   Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)
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

# long_name: Checks for timeouts using 'navicli'
# description: Checks timeouts in navicli usage that might require tuning
# priority: 600

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

# Actually run the check
is_required_file "${CITELLUS_ROOT}/var/log/cinder/volume.log"
is_required_file "${CITELLUS_ROOT}/etc/cinder/cinder.conf"

# Check if we're a server with cinder-volume running
if is_process cinder-volume; then
    # Get RPC Timeout in cinder
    TIMEOUT=$(iniparser "${CITELLUS_ROOT}/etc/cinder/cinder.conf" DEFAULT rpc_response_timeout)

    if [[ "x$TIMEOUT" != "x" ]]; then
        LINES=$(grep -E 'naviseccli.*returned' "${CITELLUS_ROOT}/var/log/cinder/volume.log"| awk -F'.*/naviseccli.*returned: 0 in |s execute' '$2>$TIMEOUT {print $2}'|wc -l)
        if [[ "x$LINES" != "x0" ]]; then
            echo $"Detected possible Navicli timeouts in cinder" >&2
            exit ${RC_FAILED}
        fi
        echo "Not detected cinder rpc_response_timeout" >&2
        exit ${RC_SKIPPED}
    fi
else
    echo "No cinder-volume running" >&2
    exit ${RC_SKIPPED}
fi

exit ${RC_OKAY}
