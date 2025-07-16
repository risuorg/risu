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

# long_name: Check for broken service dependencies
# description: Check for systemd services with broken dependencies
# priority: 400

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

BROKEN_DEPS=()

if [[ "x$RISU_LIVE" == "x1" ]]; then
    # Check current service dependencies
    if command -v systemctl >/dev/null 2>&1; then
        # Look for services that are inactive due to dependency issues
        while IFS= read -r service; do
            if [[ -n $service ]]; then
                STATUS=$(systemctl is-active "$service" 2>/dev/null || echo "unknown")
                if [[ $STATUS == "inactive" ]]; then
                    # Check if it has dependency issues
                    DEPS=$(systemctl list-dependencies "$service" --failed --no-legend --no-pager 2>/dev/null | grep -c "●" || echo "0")
                    if [[ $DEPS -gt 0 ]]; then
                        BROKEN_DEPS+=("$service")
                    fi
                fi
            fi
        done < <(systemctl list-units --type=service --no-legend --no-pager | awk '{print $1}')
    else
        echo "systemctl command not available" >&2
        exit $RC_SKIPPED
    fi
else
    # Check sosreport for service dependency information
    if [[ -f "${RISU_ROOT}/systemctl_list-units" ]]; then
        # Look for services that are inactive/failed
        while IFS= read -r line; do
            if [[ $line =~ .*\.service.*inactive ]] || [[ $line =~ .*\.service.*failed ]]; then
                SERVICE=$(echo "$line" | awk '{print $1}')
                BROKEN_DEPS+=("$SERVICE")
            fi
        done <"${RISU_ROOT}/systemctl_list-units"
    else
        echo "systemctl list-units file not found in sosreport" >&2
        exit $RC_SKIPPED
    fi
fi

# Check results
if [[ ${#BROKEN_DEPS[@]} -gt 0 ]]; then
    echo "WARNING: Found services with potential dependency issues:" >&2
    for service in "${BROKEN_DEPS[@]}"; do
        echo "  - $service" >&2
    done
    exit $RC_FAILED
else
    echo "No services found with broken dependencies" >&2
    exit $RC_OKAY
fi
