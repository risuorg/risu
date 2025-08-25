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

# long_name: Check for failed systemd services
# description: Check if there are failed systemd services
# priority: 400

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

FAILED_SERVICES=()

if [[ "x$RISU_LIVE" == "x1" ]]; then
    # Get current failed services
    if command -v systemctl >/dev/null 2>&1; then
        while IFS= read -r line; do
            if [[ -n $line ]]; then
                FAILED_SERVICES+=("$line")
            fi
        done < <(systemctl --failed --no-legend --no-pager | awk '{print $1}')
    else
        echo "systemctl command not available" >&2
        exit $RC_SKIPPED
    fi
else
    # Check sosreport for failed services
    if [[ -f "${RISU_ROOT}/systemctl_--failed" ]]; then
        while IFS= read -r line; do
            # Skip headers and empty lines
            [[ $line =~ ^UNIT ]] && continue
            [[ $line =~ ^[[:space:]]*$ ]] && continue
            [[ $line =~ ^[0-9]+ ]] && continue

            if [[ -n $line ]]; then
                SERVICE=$(echo "$line" | awk '{print $1}')
                if [[ -n $SERVICE ]]; then
                    FAILED_SERVICES+=("$SERVICE")
                fi
            fi
        done <"${RISU_ROOT}/systemctl_--failed"
    else
        echo "systemctl --failed file not found in sosreport" >&2
        exit $RC_SKIPPED
    fi
fi

# Check if any services failed
if [[ ${#FAILED_SERVICES[@]} -gt 0 ]]; then
    echo "CRITICAL: Found ${#FAILED_SERVICES[@]} failed systemd services:" >&2
    for service in "${FAILED_SERVICES[@]}"; do
        echo "  - $service" >&2
    done
    exit $RC_FAILED
else
    echo "No failed systemd services found" >&2
    exit $RC_OKAY
fi
