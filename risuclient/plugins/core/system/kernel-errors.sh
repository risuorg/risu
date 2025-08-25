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

# long_name: Check for kernel errors
# description: Check for kernel errors and warnings in system logs
# priority: 910

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

CRITICAL_ERRORS=0
WARNING_ERRORS=0

# Define critical error patterns
CRITICAL_PATTERNS=(
    "kernel BUG"
    "kernel panic"
    "Oops:"
    "BUG:"
    "segfault"
    "Call Trace:"
    "Out of memory"
    "killed process"
    "Memory corruption"
    "Hardware Error"
    "MCE:"
    "Machine check"
)

# Define warning patterns
WARNING_PATTERNS=(
    "WARNING:"
    "WARN:"
    "deprecated"
    "hung task"
    "soft lockup"
    "RCU stall"
    "NMI watchdog"
    "thermal"
    "temperature"
)

if [[ "x$RISU_LIVE" == "x1" ]]; then
    # Check current kernel messages
    if command -v dmesg >/dev/null 2>&1; then
        DMESG_OUTPUT=$(dmesg -T 2>/dev/null || dmesg)

        # Check for critical errors
        for pattern in "${CRITICAL_PATTERNS[@]}"; do
            COUNT=$(echo "$DMESG_OUTPUT" | grep -ci "$pattern")
            if [[ $COUNT -gt 0 ]]; then
                echo "CRITICAL: Found $COUNT instances of '$pattern' in kernel messages" >&2
                CRITICAL_ERRORS=$((CRITICAL_ERRORS + COUNT))
            fi
        done

        # Check for warnings
        for pattern in "${WARNING_PATTERNS[@]}"; do
            COUNT=$(echo "$DMESG_OUTPUT" | grep -ci "$pattern")
            if [[ $COUNT -gt 0 ]]; then
                echo "WARNING: Found $COUNT instances of '$pattern' in kernel messages" >&2
                WARNING_ERRORS=$((WARNING_ERRORS + COUNT))
            fi
        done
    else
        echo "dmesg command not available" >&2
        exit $RC_SKIPPED
    fi
else
    # Check sosreport for kernel messages
    if [[ -f "${RISU_ROOT}/dmesg" ]]; then
        DMESG_OUTPUT=$(cat "${RISU_ROOT}/dmesg")

        # Check for critical errors
        for pattern in "${CRITICAL_PATTERNS[@]}"; do
            COUNT=$(echo "$DMESG_OUTPUT" | grep -ci "$pattern")
            if [[ $COUNT -gt 0 ]]; then
                echo "CRITICAL: Found $COUNT instances of '$pattern' in kernel messages" >&2
                CRITICAL_ERRORS=$((CRITICAL_ERRORS + COUNT))
            fi
        done

        # Check for warnings
        for pattern in "${WARNING_PATTERNS[@]}"; do
            COUNT=$(echo "$DMESG_OUTPUT" | grep -ci "$pattern")
            if [[ $COUNT -gt 0 ]]; then
                echo "WARNING: Found $COUNT instances of '$pattern' in kernel messages" >&2
                WARNING_ERRORS=$((WARNING_ERRORS + COUNT))
            fi
        done
    else
        echo "dmesg file not found in sosreport" >&2
        exit $RC_SKIPPED
    fi
fi

# Check results
if [[ $CRITICAL_ERRORS -gt 0 ]]; then
    echo "Found $CRITICAL_ERRORS critical kernel errors" >&2
    exit $RC_FAILED
elif [[ $WARNING_ERRORS -gt 10 ]]; then
    echo "Found $WARNING_ERRORS kernel warnings (threshold: 10)" >&2
    exit $RC_FAILED
elif [[ $WARNING_ERRORS -gt 0 ]]; then
    echo "Found $WARNING_ERRORS kernel warnings" >&2
    exit $RC_OKAY
else
    echo "No significant kernel errors or warnings found" >&2
    exit $RC_OKAY
fi
