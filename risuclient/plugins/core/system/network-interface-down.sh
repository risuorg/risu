#!/bin/bash

# Copyright (C) 2024 Pablo Iranzo Gómez (Pablo.Iranzo@gmail.com)

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

# long_name: Check for network interfaces down
# description: Check if configured network interfaces are down
# priority: 870

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

ISSUES_FOUND=0

if [[ "x$RISU_LIVE" == "x1" ]]; then
    # Get current network interface status
    if command -v ip >/dev/null 2>&1; then
        # Check all non-loopback interfaces
        while IFS= read -r line; do
            INTERFACE=$(echo "$line" | awk '{print $2}' | tr -d ':')
            STATUS=$(echo "$line" | grep -o "state [A-Z]*" | awk '{print $2}')

            # Skip loopback and virtual interfaces
            [[ $INTERFACE =~ ^lo ]] && continue
            [[ $INTERFACE =~ ^docker ]] && continue
            [[ $INTERFACE =~ ^veth ]] && continue
            [[ $INTERFACE =~ ^br- ]] && continue

            if [[ $STATUS == "DOWN" ]]; then
                echo "WARNING: Network interface $INTERFACE is DOWN" >&2
                ISSUES_FOUND=1
            elif [[ $STATUS == "UNKNOWN" ]]; then
                echo "INFO: Network interface $INTERFACE is in UNKNOWN state" >&2
            fi
        done < <(ip link show | grep -E "^[0-9]+:")
    else
        echo "ip command not available" >&2
        exit $RC_SKIPPED
    fi
else
    # Check sosreport for network interface status
    if [[ -f "${RISU_ROOT}/ip_link_show" ]]; then
        while IFS= read -r line; do
            INTERFACE=$(echo "$line" | awk '{print $2}' | tr -d ':')
            STATUS=$(echo "$line" | grep -o "state [A-Z]*" | awk '{print $2}')

            # Skip loopback and virtual interfaces
            [[ $INTERFACE =~ ^lo ]] && continue
            [[ $INTERFACE =~ ^docker ]] && continue
            [[ $INTERFACE =~ ^veth ]] && continue
            [[ $INTERFACE =~ ^br- ]] && continue

            if [[ $STATUS == "DOWN" ]]; then
                echo "WARNING: Network interface $INTERFACE was DOWN" >&2
                ISSUES_FOUND=1
            elif [[ $STATUS == "UNKNOWN" ]]; then
                echo "INFO: Network interface $INTERFACE was in UNKNOWN state" >&2
            fi
        done <"${RISU_ROOT}/ip_link_show"
    elif [[ -f "${RISU_ROOT}/proc/net/dev" ]]; then
        # Fallback to /proc/net/dev
        while IFS= read -r line; do
            INTERFACE=$(echo "$line" | awk -F: '{print $1}' | tr -d ' ')

            # Skip loopback and virtual interfaces
            [[ $INTERFACE =~ ^lo ]] && continue
            [[ $INTERFACE =~ ^docker ]] && continue
            [[ $INTERFACE =~ ^veth ]] && continue
            [[ $INTERFACE =~ ^br- ]] && continue
            [[ $INTERFACE =~ ^Inter- ]] && continue
            [[ $INTERFACE =~ ^face ]] && continue

            # If we can't determine status from /proc/net/dev, skip
            if [[ -n $INTERFACE ]]; then
                echo "INFO: Found interface $INTERFACE in /proc/net/dev" >&2
            fi
        done <"${RISU_ROOT}/proc/net/dev"
    else
        echo "No network interface information found in sosreport" >&2
        exit $RC_SKIPPED
    fi
fi

if [[ $ISSUES_FOUND -eq 1 ]]; then
    exit $RC_FAILED
else
    echo "All network interfaces are up or in acceptable state" >&2
    exit $RC_OKAY
fi
