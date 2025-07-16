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

# long_name: Check for slow boot time
# description: Check if system boot time is above acceptable thresholds
# priority: 900

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

# Set thresholds in seconds
WARNING_THRESHOLD=120  # 2 minutes
CRITICAL_THRESHOLD=300 # 5 minutes

if [[ "x$RISU_LIVE" == "x1" ]]; then
    # Get current boot time
    if command -v systemd-analyze >/dev/null 2>&1; then
        BOOT_TIME=$(systemd-analyze | head -1 | grep -o '[0-9]*\.[0-9]*s' | head -1 | sed 's/s//')
        if [[ -n $BOOT_TIME ]]; then
            BOOT_TIME_INT=$(echo "$BOOT_TIME" | cut -d. -f1)
        else
            echo "Could not determine boot time from systemd-analyze" >&2
            exit $RC_SKIPPED
        fi
    else
        echo "systemd-analyze command not available" >&2
        exit $RC_SKIPPED
    fi
else
    # Check sosreport for boot time
    if [[ -f "${RISU_ROOT}/systemd-analyze" ]]; then
        BOOT_TIME=$(head -1 "${RISU_ROOT}/systemd-analyze" | grep -o '[0-9]*\.[0-9]*s' | head -1 | sed 's/s//')
        if [[ -n $BOOT_TIME ]]; then
            BOOT_TIME_INT=$(echo "$BOOT_TIME" | cut -d. -f1)
        else
            echo "Could not determine boot time from sosreport" >&2
            exit $RC_SKIPPED
        fi
    else
        echo "systemd-analyze file not found in sosreport" >&2
        exit $RC_SKIPPED
    fi
fi

# Check boot time against thresholds
if [[ -n $BOOT_TIME_INT ]]; then
    if [[ $BOOT_TIME_INT -ge $CRITICAL_THRESHOLD ]]; then
        echo "CRITICAL: System boot time is ${BOOT_TIME}s (threshold: ${CRITICAL_THRESHOLD}s)" >&2
        exit $RC_FAILED
    elif [[ $BOOT_TIME_INT -ge $WARNING_THRESHOLD ]]; then
        echo "WARNING: System boot time is ${BOOT_TIME}s (threshold: ${WARNING_THRESHOLD}s)" >&2
        exit $RC_FAILED
    else
        echo "System boot time is acceptable: ${BOOT_TIME}s" >&2
        exit $RC_OKAY
    fi
else
    echo "Could not determine boot time" >&2
    exit $RC_SKIPPED
fi
