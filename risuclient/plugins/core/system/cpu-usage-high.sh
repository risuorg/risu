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

# long_name: Check for high CPU usage
# description: Check if CPU usage is above critical thresholds
# priority: 920

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

# Set thresholds
CPU_WARNING_THRESHOLD=70
CPU_CRITICAL_THRESHOLD=90

if [[ "x$RISU_LIVE" == "x1" ]]; then
    # Get current CPU usage (1-minute average)
    if is_lineinfile "^top" "${RISU_ROOT}/ps"; then
        # Get CPU usage from ps output
        CPU_USAGE=$(ps -eo pcpu | awk '{sum += $1} END {print sum}')
    else
        # Use uptime to get load average
        CPU_USAGE=$(uptime | awk '{print $10}' | sed 's/,//')
        # Convert load average to percentage (rough approximation)
        CPU_COUNT=$(nproc)
        CPU_USAGE=$(echo "scale=2; $CPU_USAGE / $CPU_COUNT * 100" | bc 2>/dev/null || echo "0")
    fi
else
    # Check sosreport for CPU usage patterns
    if [[ -f "${RISU_ROOT}/uptime" ]]; then
        LOAD_AVG=$(cat "${RISU_ROOT}/uptime" | awk '{print $10}' | sed 's/,//')
        CPU_COUNT=$(grep -c "^processor" "${RISU_ROOT}/proc/cpuinfo" 2>/dev/null || echo "1")
        CPU_USAGE=$(echo "scale=2; $LOAD_AVG / $CPU_COUNT * 100" | bc 2>/dev/null || echo "0")
    else
        echo "uptime file not found in sosreport" >&2
        exit $RC_SKIPPED
    fi
fi

# Check CPU usage against thresholds
if [[ -n $CPU_USAGE ]]; then
    CPU_INT=$(echo "$CPU_USAGE" | cut -d. -f1)
    if [[ $CPU_INT -ge $CPU_CRITICAL_THRESHOLD ]]; then
        echo "CRITICAL: CPU usage is ${CPU_USAGE}% (threshold: ${CPU_CRITICAL_THRESHOLD}%)" >&2
        exit $RC_FAILED
    elif [[ $CPU_INT -ge $CPU_WARNING_THRESHOLD ]]; then
        echo "WARNING: CPU usage is ${CPU_USAGE}% (threshold: ${CPU_WARNING_THRESHOLD}%)" >&2
        exit $RC_FAILED
    else
        echo "CPU usage is normal: ${CPU_USAGE}%" >&2
        exit $RC_OKAY
    fi
else
    echo "Could not determine CPU usage" >&2
    exit $RC_SKIPPED
fi
