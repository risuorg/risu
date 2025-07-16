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

# long_name: Check for high system load average
# description: Check if system load average is above critical thresholds
# priority: 400

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

if [[ "x$RISU_LIVE" == "x1" ]]; then
    # Get current load average
    if [[ -f "/proc/loadavg" ]]; then
        LOAD_INFO=$(cat /proc/loadavg)
        LOAD_1MIN=$(echo "$LOAD_INFO" | awk '{print $1}')
        LOAD_5MIN=$(echo "$LOAD_INFO" | awk '{print $2}')
        LOAD_15MIN=$(echo "$LOAD_INFO" | awk '{print $3}')
        CPU_COUNT=$(nproc)
    else
        echo "/proc/loadavg not available" >&2
        exit $RC_SKIPPED
    fi
else
    # Check sosreport for load average
    if [[ -f "${RISU_ROOT}/proc/loadavg" ]]; then
        LOAD_INFO=$(cat "${RISU_ROOT}/proc/loadavg")
        LOAD_1MIN=$(echo "$LOAD_INFO" | awk '{print $1}')
        LOAD_5MIN=$(echo "$LOAD_INFO" | awk '{print $2}')
        LOAD_15MIN=$(echo "$LOAD_INFO" | awk '{print $3}')
        CPU_COUNT=$(grep -c "^processor" "${RISU_ROOT}/proc/cpuinfo" 2>/dev/null || echo "1")
    else
        echo "loadavg file not found in sosreport" >&2
        exit $RC_SKIPPED
    fi
fi

# Calculate load thresholds based on CPU count
WARNING_THRESHOLD=$(echo "scale=2; $CPU_COUNT * 0.7" | bc 2>/dev/null || echo "0.7")
CRITICAL_THRESHOLD=$(echo "scale=2; $CPU_COUNT * 1.0" | bc 2>/dev/null || echo "1.0")

ISSUES_FOUND=0

# Check 1-minute load average
LOAD_1MIN_COMPARE=$(echo "$LOAD_1MIN > $CRITICAL_THRESHOLD" | bc 2>/dev/null || echo "0")
if [[ $LOAD_1MIN_COMPARE == "1" ]]; then
    echo "CRITICAL: 1-minute load average is $LOAD_1MIN (threshold: $CRITICAL_THRESHOLD for $CPU_COUNT CPUs)" >&2
    ISSUES_FOUND=1
else
    LOAD_1MIN_COMPARE=$(echo "$LOAD_1MIN > $WARNING_THRESHOLD" | bc 2>/dev/null || echo "0")
    if [[ $LOAD_1MIN_COMPARE == "1" ]]; then
        echo "WARNING: 1-minute load average is $LOAD_1MIN (threshold: $WARNING_THRESHOLD for $CPU_COUNT CPUs)" >&2
        ISSUES_FOUND=1
    fi
fi

# Check 5-minute load average
LOAD_5MIN_COMPARE=$(echo "$LOAD_5MIN > $CRITICAL_THRESHOLD" | bc 2>/dev/null || echo "0")
if [[ $LOAD_5MIN_COMPARE == "1" ]]; then
    echo "CRITICAL: 5-minute load average is $LOAD_5MIN (threshold: $CRITICAL_THRESHOLD for $CPU_COUNT CPUs)" >&2
    ISSUES_FOUND=1
else
    LOAD_5MIN_COMPARE=$(echo "$LOAD_5MIN > $WARNING_THRESHOLD" | bc 2>/dev/null || echo "0")
    if [[ $LOAD_5MIN_COMPARE == "1" ]]; then
        echo "WARNING: 5-minute load average is $LOAD_5MIN (threshold: $WARNING_THRESHOLD for $CPU_COUNT CPUs)" >&2
        ISSUES_FOUND=1
    fi
fi

# Check 15-minute load average
LOAD_15MIN_COMPARE=$(echo "$LOAD_15MIN > $CRITICAL_THRESHOLD" | bc 2>/dev/null || echo "0")
if [[ $LOAD_15MIN_COMPARE == "1" ]]; then
    echo "CRITICAL: 15-minute load average is $LOAD_15MIN (threshold: $CRITICAL_THRESHOLD for $CPU_COUNT CPUs)" >&2
    ISSUES_FOUND=1
else
    LOAD_15MIN_COMPARE=$(echo "$LOAD_15MIN > $WARNING_THRESHOLD" | bc 2>/dev/null || echo "0")
    if [[ $LOAD_15MIN_COMPARE == "1" ]]; then
        echo "WARNING: 15-minute load average is $LOAD_15MIN (threshold: $WARNING_THRESHOLD for $CPU_COUNT CPUs)" >&2
        ISSUES_FOUND=1
    fi
fi

if [[ $ISSUES_FOUND -eq 1 ]]; then
    exit $RC_FAILED
else
    echo "Load averages are within acceptable thresholds: 1min=$LOAD_1MIN, 5min=$LOAD_5MIN, 15min=$LOAD_15MIN" >&2
    exit $RC_OKAY
fi
