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

# long_name: Check for open files limit
# description: Check if system is approaching open file limits
# priority: 400

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

# Set thresholds as percentage of max open files
WARNING_THRESHOLD=70
CRITICAL_THRESHOLD=90

if [[ "x$RISU_LIVE" == "x1" ]]; then
    # Get current open files information
    if [[ -f "/proc/sys/fs/file-nr" ]]; then
        FILE_INFO=$(cat /proc/sys/fs/file-nr)
        OPEN_FILES=$(echo "$FILE_INFO" | awk '{print $1}')
        MAX_FILES=$(echo "$FILE_INFO" | awk '{print $3}')

        if [[ $MAX_FILES -gt 0 ]]; then
            USAGE_PERCENT=$(echo "scale=2; $OPEN_FILES * 100 / $MAX_FILES" | bc 2>/dev/null || echo "0")
        else
            echo "Cannot determine max open files" >&2
            exit $RC_SKIPPED
        fi
    else
        echo "/proc/sys/fs/file-nr not available" >&2
        exit $RC_SKIPPED
    fi
else
    # Check sosreport for open files information
    if [[ -f "${RISU_ROOT}/proc/sys/fs/file-nr" ]]; then
        FILE_INFO=$(cat "${RISU_ROOT}/proc/sys/fs/file-nr")
        OPEN_FILES=$(echo "$FILE_INFO" | awk '{print $1}')
        MAX_FILES=$(echo "$FILE_INFO" | awk '{print $3}')

        if [[ $MAX_FILES -gt 0 ]]; then
            USAGE_PERCENT=$(echo "scale=2; $OPEN_FILES * 100 / $MAX_FILES" | bc 2>/dev/null || echo "0")
        else
            echo "Cannot determine max open files from sosreport" >&2
            exit $RC_SKIPPED
        fi
    else
        echo "file-nr file not found in sosreport" >&2
        exit $RC_SKIPPED
    fi
fi

# Check usage against thresholds
if [[ -n $USAGE_PERCENT ]]; then
    USAGE_INT=$(echo "$USAGE_PERCENT" | cut -d. -f1)
    if [[ $USAGE_INT -ge $CRITICAL_THRESHOLD ]]; then
        echo "CRITICAL: Open files usage is ${USAGE_PERCENT}% ($OPEN_FILES/$MAX_FILES) (threshold: ${CRITICAL_THRESHOLD}%)" >&2
        exit $RC_FAILED
    elif [[ $USAGE_INT -ge $WARNING_THRESHOLD ]]; then
        echo "WARNING: Open files usage is ${USAGE_PERCENT}% ($OPEN_FILES/$MAX_FILES) (threshold: ${WARNING_THRESHOLD}%)" >&2
        exit $RC_FAILED
    else
        echo "Open files usage is normal: ${USAGE_PERCENT}% ($OPEN_FILES/$MAX_FILES)" >&2
        exit $RC_OKAY
    fi
else
    echo "Could not determine open files usage" >&2
    exit $RC_SKIPPED
fi
