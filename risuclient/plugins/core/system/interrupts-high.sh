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

# long_name: Check for high interrupt rate
# description: Check if interrupt rate is above critical thresholds
# priority: 400

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

# Set thresholds (interrupts per second)
WARNING_THRESHOLD=50000
CRITICAL_THRESHOLD=200000

if [[ "x$RISU_LIVE" == "x1" ]]; then
    # Get current interrupts
    if [[ -f "/proc/stat" ]]; then
        INTERRUPTS=$(grep "^intr" /proc/stat | awk '{print $2}')

        # Need to sample twice to get rate
        sleep 1
        INTERRUPTS_AFTER=$(grep "^intr" /proc/stat | awk '{print $2}')

        if [[ -n $INTERRUPTS && -n $INTERRUPTS_AFTER ]]; then
            INTR_RATE=$((INTERRUPTS_AFTER - INTERRUPTS))
        else
            echo "Could not determine interrupt rate" >&2
            exit $RC_SKIPPED
        fi
    else
        echo "/proc/stat not available" >&2
        exit $RC_SKIPPED
    fi
else
    # Check sosreport for interrupts
    if [[ -f "${RISU_ROOT}/proc/stat" ]]; then
        INTERRUPTS=$(grep "^intr" "${RISU_ROOT}/proc/stat" | awk '{print $2}')

        # For sosreport, we can't calculate rate, so check absolute value
        if [[ -n $INTERRUPTS ]]; then
            # Estimate rate based on uptime
            if [[ -f "${RISU_ROOT}/proc/uptime" ]]; then
                UPTIME=$(awk '{print $1}' "${RISU_ROOT}/proc/uptime")
                INTR_RATE=$(echo "scale=0; $INTERRUPTS / $UPTIME" | bc 2>/dev/null || echo "0")
            else
                echo "Cannot determine interrupt rate from sosreport without uptime" >&2
                exit $RC_SKIPPED
            fi
        else
            echo "Cannot determine interrupts from sosreport" >&2
            exit $RC_SKIPPED
        fi
    else
        echo "proc/stat file not found in sosreport" >&2
        exit $RC_SKIPPED
    fi
fi

# Get top interrupt sources
TOP_INTERRUPTS=""
if [[ "x$RISU_LIVE" == "x1" ]]; then
    if [[ -f "/proc/interrupts" ]]; then
        TOP_INTERRUPTS=$(grep -v "CPU" /proc/interrupts | sort -k2 -nr | head -3 | awk '{print $1 " " $NF}')
    fi
else
    if [[ -f "${RISU_ROOT}/proc/interrupts" ]]; then
        TOP_INTERRUPTS=$(grep -v "CPU" "${RISU_ROOT}/proc/interrupts" | sort -k2 -nr | head -3 | awk '{print $1 " " $NF}')
    fi
fi

# Check interrupt rate against thresholds
if [[ $INTR_RATE -ge $CRITICAL_THRESHOLD ]]; then
    echo "CRITICAL: Interrupt rate is $INTR_RATE/sec (threshold: $CRITICAL_THRESHOLD/sec)" >&2
    if [[ -n $TOP_INTERRUPTS ]]; then
        echo "Top interrupt sources:" >&2
        echo "$TOP_INTERRUPTS" >&2
    fi
    exit $RC_FAILED
elif [[ $INTR_RATE -ge $WARNING_THRESHOLD ]]; then
    echo "WARNING: Interrupt rate is $INTR_RATE/sec (threshold: $WARNING_THRESHOLD/sec)" >&2
    if [[ -n $TOP_INTERRUPTS ]]; then
        echo "Top interrupt sources:" >&2
        echo "$TOP_INTERRUPTS" >&2
    fi
    exit $RC_FAILED
else
    echo "Interrupt rate is normal: $INTR_RATE/sec" >&2
    exit $RC_OKAY
fi
