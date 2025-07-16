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

# long_name: Check for service restart loops
# description: Check for systemd services that are restarting in loops
# priority: 400

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

RESTART_THRESHOLD=5
LOOPING_SERVICES=()

if [[ "x$RISU_LIVE" == "x1" ]]; then
    # Check current service restart counts
    if command -v systemctl >/dev/null 2>&1; then
        # Get failed services and check their restart counts
        while IFS= read -r service; do
            if [[ -n $service ]]; then
                RESTART_COUNT=$(systemctl show "$service" -p NRestarts --value 2>/dev/null || echo "0")
                if [[ $RESTART_COUNT =~ ^[0-9]+$ ]] && [[ $RESTART_COUNT -ge $RESTART_THRESHOLD ]]; then
                    LOOPING_SERVICES+=("$service ($RESTART_COUNT restarts)")
                fi
            fi
        done < <(systemctl list-units --state=failed --no-legend --no-pager | awk '{print $1}')

        # Also check active services with high restart counts
        while IFS= read -r service; do
            if [[ -n $service ]]; then
                RESTART_COUNT=$(systemctl show "$service" -p NRestarts --value 2>/dev/null || echo "0")
                if [[ $RESTART_COUNT =~ ^[0-9]+$ ]] && [[ $RESTART_COUNT -ge $RESTART_THRESHOLD ]]; then
                    LOOPING_SERVICES+=("$service ($RESTART_COUNT restarts)")
                fi
            fi
        done < <(systemctl list-units --state=active --no-legend --no-pager | grep "\.service" | awk '{print $1}')
    else
        echo "systemctl command not available" >&2
        exit $RC_SKIPPED
    fi
else
    # Check sosreport for service restart information
    if [[ -f "${RISU_ROOT}/systemctl_list-units" ]]; then
        # Look for services that might be restarting
        while IFS= read -r line; do
            if [[ $line =~ .*\.service.*failed ]]; then
                SERVICE=$(echo "$line" | awk '{print $1}')
                LOOPING_SERVICES+=("$SERVICE (failed)")
            fi
        done <"${RISU_ROOT}/systemctl_list-units"
    else
        echo "systemctl list-units file not found in sosreport" >&2
        exit $RC_SKIPPED
    fi
fi

# Check results
if [[ ${#LOOPING_SERVICES[@]} -gt 0 ]]; then
    echo "WARNING: Found services with potential restart loops:" >&2
    for service in "${LOOPING_SERVICES[@]}"; do
        echo "  - $service" >&2
    done
    exit $RC_FAILED
else
    echo "No services found with excessive restart counts" >&2
    exit $RC_OKAY
fi
