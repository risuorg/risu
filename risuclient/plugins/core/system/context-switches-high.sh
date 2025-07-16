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

# long_name: Check for high context switch rate
# description: Check if context switch rate is above critical thresholds
# priority: 400

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

# Set thresholds (context switches per second)
WARNING_THRESHOLD=100000
CRITICAL_THRESHOLD=500000

if [[ "x$RISU_LIVE" == "x1" ]]; then
    # Get current context switches
    if [[ -f "/proc/stat" ]]; then
        CTXT_SWITCHES=$(grep "^ctxt" /proc/stat | awk '{print $2}')

        # Need to sample twice to get rate
        sleep 1
        CTXT_SWITCHES_AFTER=$(grep "^ctxt" /proc/stat | awk '{print $2}')

        if [[ -n $CTXT_SWITCHES && -n $CTXT_SWITCHES_AFTER ]]; then
            CTXT_RATE=$((CTXT_SWITCHES_AFTER - CTXT_SWITCHES))
        else
            echo "Could not determine context switch rate" >&2
            exit $RC_SKIPPED
        fi
    else
        echo "/proc/stat not available" >&2
        exit $RC_SKIPPED
    fi
else
    # Check sosreport for context switches
    if [[ -f "${RISU_ROOT}/proc/stat" ]]; then
        CTXT_SWITCHES=$(grep "^ctxt" "${RISU_ROOT}/proc/stat" | awk '{print $2}')

        # For sosreport, we can't calculate rate, so check absolute value
        if [[ -n $CTXT_SWITCHES ]]; then
            # Estimate rate based on uptime
            if [[ -f "${RISU_ROOT}/proc/uptime" ]]; then
                UPTIME=$(awk '{print $1}' "${RISU_ROOT}/proc/uptime")
                CTXT_RATE=$(echo "scale=0; $CTXT_SWITCHES / $UPTIME" | bc 2>/dev/null || echo "0")
            else
                echo "Cannot determine context switch rate from sosreport without uptime" >&2
                exit $RC_SKIPPED
            fi
        else
            echo "Cannot determine context switches from sosreport" >&2
            exit $RC_SKIPPED
        fi
    else
        echo "proc/stat file not found in sosreport" >&2
        exit $RC_SKIPPED
    fi
fi

# Check context switch rate against thresholds
if [[ $CTXT_RATE -ge $CRITICAL_THRESHOLD ]]; then
    echo "CRITICAL: Context switch rate is $CTXT_RATE/sec (threshold: $CRITICAL_THRESHOLD/sec)" >&2
    exit $RC_FAILED
elif [[ $CTXT_RATE -ge $WARNING_THRESHOLD ]]; then
    echo "WARNING: Context switch rate is $CTXT_RATE/sec (threshold: $WARNING_THRESHOLD/sec)" >&2
    exit $RC_FAILED
else
    echo "Context switch rate is normal: $CTXT_RATE/sec" >&2
    exit $RC_OKAY
fi
