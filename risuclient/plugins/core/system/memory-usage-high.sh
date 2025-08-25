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

# long_name: Check for high memory usage
# description: Check if memory usage is above critical thresholds
# priority: 930

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

# Set thresholds
MEMORY_WARNING_THRESHOLD=80
MEMORY_CRITICAL_THRESHOLD=95

if [[ "x$RISU_LIVE" == "x1" ]]; then
    # Get current memory usage
    if command -v free >/dev/null 2>&1; then
        MEMORY_INFO=$(free -m | grep "^Mem:")
        TOTAL_MEM=$(echo $MEMORY_INFO | awk '{print $2}')
        USED_MEM=$(echo $MEMORY_INFO | awk '{print $3}')
        MEMORY_USAGE=$(echo "scale=2; $USED_MEM / $TOTAL_MEM * 100" | bc 2>/dev/null || echo "0")
    else
        echo "free command not available" >&2
        exit $RC_SKIPPED
    fi
else
    # Check sosreport for memory usage
    if [[ -f "${RISU_ROOT}/proc/meminfo" ]]; then
        TOTAL_MEM=$(grep "^MemTotal:" "${RISU_ROOT}/proc/meminfo" | awk '{print $2}')
        FREE_MEM=$(grep "^MemFree:" "${RISU_ROOT}/proc/meminfo" | awk '{print $2}')
        BUFFERS=$(grep "^Buffers:" "${RISU_ROOT}/proc/meminfo" | awk '{print $2}')
        CACHED=$(grep "^Cached:" "${RISU_ROOT}/proc/meminfo" | awk '{print $2}')

        # Calculate used memory (total - free - buffers - cached)
        USED_MEM=$(echo "scale=2; ($TOTAL_MEM - $FREE_MEM - $BUFFERS - $CACHED) / 1024" | bc 2>/dev/null || echo "0")
        TOTAL_MEM=$(echo "scale=2; $TOTAL_MEM / 1024" | bc 2>/dev/null || echo "0")
        MEMORY_USAGE=$(echo "scale=2; $USED_MEM / $TOTAL_MEM * 100" | bc 2>/dev/null || echo "0")
    else
        echo "meminfo file not found in sosreport" >&2
        exit $RC_SKIPPED
    fi
fi

# Check memory usage against thresholds
if [[ -n $MEMORY_USAGE ]]; then
    MEMORY_INT=$(echo "$MEMORY_USAGE" | cut -d. -f1)
    if [[ $MEMORY_INT -ge $MEMORY_CRITICAL_THRESHOLD ]]; then
        echo "CRITICAL: Memory usage is ${MEMORY_USAGE}% (threshold: ${MEMORY_CRITICAL_THRESHOLD}%)" >&2
        exit $RC_FAILED
    elif [[ $MEMORY_INT -ge $MEMORY_WARNING_THRESHOLD ]]; then
        echo "WARNING: Memory usage is ${MEMORY_USAGE}% (threshold: ${MEMORY_WARNING_THRESHOLD}%)" >&2
        exit $RC_FAILED
    else
        echo "Memory usage is normal: ${MEMORY_USAGE}%" >&2
        exit $RC_OKAY
    fi
else
    echo "Could not determine memory usage" >&2
    exit $RC_SKIPPED
fi
