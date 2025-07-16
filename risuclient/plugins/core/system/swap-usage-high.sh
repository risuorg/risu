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

# long_name: Check for high swap usage
# description: Check if swap usage is above critical thresholds
# priority: 400

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

# Set thresholds
SWAP_WARNING_THRESHOLD=50
SWAP_CRITICAL_THRESHOLD=80

if [[ "x$RISU_LIVE" == "x1" ]]; then
    # Get current swap usage
    if command -v free >/dev/null 2>&1; then
        SWAP_INFO=$(free -m | grep "^Swap:")
        TOTAL_SWAP=$(echo $SWAP_INFO | awk '{print $2}')
        USED_SWAP=$(echo $SWAP_INFO | awk '{print $3}')

        if [[ $TOTAL_SWAP -eq 0 ]]; then
            echo "No swap space configured" >&2
            exit $RC_OKAY
        fi

        SWAP_USAGE=$(echo "scale=2; $USED_SWAP / $TOTAL_SWAP * 100" | bc 2>/dev/null || echo "0")
    else
        echo "free command not available" >&2
        exit $RC_SKIPPED
    fi
else
    # Check sosreport for swap usage
    if [[ -f "${RISU_ROOT}/proc/meminfo" ]]; then
        TOTAL_SWAP=$(grep "^SwapTotal:" "${RISU_ROOT}/proc/meminfo" | awk '{print $2}')
        FREE_SWAP=$(grep "^SwapFree:" "${RISU_ROOT}/proc/meminfo" | awk '{print $2}')

        if [[ $TOTAL_SWAP -eq 0 ]]; then
            echo "No swap space was configured" >&2
            exit $RC_OKAY
        fi

        USED_SWAP=$(echo "scale=2; ($TOTAL_SWAP - $FREE_SWAP) / 1024" | bc 2>/dev/null || echo "0")
        TOTAL_SWAP=$(echo "scale=2; $TOTAL_SWAP / 1024" | bc 2>/dev/null || echo "0")
        SWAP_USAGE=$(echo "scale=2; $USED_SWAP / $TOTAL_SWAP * 100" | bc 2>/dev/null || echo "0")
    else
        echo "meminfo file not found in sosreport" >&2
        exit $RC_SKIPPED
    fi
fi

# Check swap usage against thresholds
if [[ -n $SWAP_USAGE ]]; then
    SWAP_INT=$(echo "$SWAP_USAGE" | cut -d. -f1)
    if [[ $SWAP_INT -ge $SWAP_CRITICAL_THRESHOLD ]]; then
        echo "CRITICAL: Swap usage is ${SWAP_USAGE}% (threshold: ${SWAP_CRITICAL_THRESHOLD}%)" >&2
        exit $RC_FAILED
    elif [[ $SWAP_INT -ge $SWAP_WARNING_THRESHOLD ]]; then
        echo "WARNING: Swap usage is ${SWAP_USAGE}% (threshold: ${SWAP_WARNING_THRESHOLD}%)" >&2
        exit $RC_FAILED
    else
        echo "Swap usage is normal: ${SWAP_USAGE}%" >&2
        exit $RC_OKAY
    fi
else
    echo "Could not determine swap usage" >&2
    exit $RC_SKIPPED
fi
