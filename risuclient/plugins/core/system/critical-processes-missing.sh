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

# long_name: Check for missing critical processes
# description: Check if critical system processes are running
# priority: 400

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

# Define critical processes to check
CRITICAL_PROCESSES=(
    "init"
    "systemd"
    "kthreadd"
    "ksoftirqd"
    "migration"
    "rcu_"
    "watchdog"
    "sshd"
    "NetworkManager"
    "chronyd"
    "rsyslog"
    "dbus"
)

MISSING_PROCESSES=()

if [[ "x$RISU_LIVE" == "x1" ]]; then
    # Check current running processes
    if command -v ps >/dev/null 2>&1; then
        RUNNING_PROCESSES=$(ps -eo comm --no-headers)

        for process in "${CRITICAL_PROCESSES[@]}"; do
            if ! echo "$RUNNING_PROCESSES" | grep -q "$process"; then
                MISSING_PROCESSES+=("$process")
            fi
        done
    else
        echo "ps command not available" >&2
        exit $RC_SKIPPED
    fi
else
    # Check sosreport for running processes
    if [[ -f "${RISU_ROOT}/ps" ]]; then
        RUNNING_PROCESSES=$(awk '{print $11}' "${RISU_ROOT}/ps" | sort -u)

        for process in "${CRITICAL_PROCESSES[@]}"; do
            if ! echo "$RUNNING_PROCESSES" | grep -q "$process"; then
                MISSING_PROCESSES+=("$process")
            fi
        done
    else
        echo "ps file not found in sosreport" >&2
        exit $RC_SKIPPED
    fi
fi

# Check if any critical processes are missing
if [[ ${#MISSING_PROCESSES[@]} -gt 0 ]]; then
    echo "WARNING: Missing critical processes:" >&2
    for process in "${MISSING_PROCESSES[@]}"; do
        echo "  - $process" >&2
    done
    exit $RC_FAILED
else
    echo "All critical processes are running" >&2
    exit $RC_OKAY
fi
