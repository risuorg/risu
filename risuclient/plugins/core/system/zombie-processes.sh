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

# long_name: Check for zombie processes
# description: Check if there are zombie processes on the system
# priority: 400

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

ZOMBIE_COUNT=0

if [[ "x$RISU_LIVE" == "x1" ]]; then
    # Get current zombie processes
    if command -v ps >/dev/null 2>&1; then
        ZOMBIE_COUNT=$(ps aux | awk '$8 ~ /^Z/ {print $2}' | wc -l)
        if [[ $ZOMBIE_COUNT -gt 0 ]]; then
            echo "Found $ZOMBIE_COUNT zombie processes:" >&2
            ps aux | awk '$8 ~ /^Z/ {print "PID: " $2 " PPID: " $3 " Command: " $11}' >&2
        fi
    else
        echo "ps command not available" >&2
        exit $RC_SKIPPED
    fi
else
    # Check sosreport for zombie processes
    if [[ -f "${RISU_ROOT}/ps" ]]; then
        ZOMBIE_COUNT=$(grep " Z " "${RISU_ROOT}/ps" | wc -l)
        if [[ $ZOMBIE_COUNT -gt 0 ]]; then
            echo "Found $ZOMBIE_COUNT zombie processes in sosreport:" >&2
            grep " Z " "${RISU_ROOT}/ps" | awk '{print "PID: " $2 " PPID: " $3 " Command: " $11}' >&2
        fi
    else
        echo "ps file not found in sosreport" >&2
        exit $RC_SKIPPED
    fi
fi

# Set thresholds for zombie processes
WARNING_THRESHOLD=5
CRITICAL_THRESHOLD=20

if [[ $ZOMBIE_COUNT -ge $CRITICAL_THRESHOLD ]]; then
    echo "CRITICAL: Found $ZOMBIE_COUNT zombie processes (threshold: $CRITICAL_THRESHOLD)" >&2
    exit $RC_FAILED
elif [[ $ZOMBIE_COUNT -ge $WARNING_THRESHOLD ]]; then
    echo "WARNING: Found $ZOMBIE_COUNT zombie processes (threshold: $WARNING_THRESHOLD)" >&2
    exit $RC_FAILED
elif [[ $ZOMBIE_COUNT -gt 0 ]]; then
    echo "INFO: Found $ZOMBIE_COUNT zombie processes" >&2
    exit $RC_OKAY
else
    echo "No zombie processes found" >&2
    exit $RC_OKAY
fi
