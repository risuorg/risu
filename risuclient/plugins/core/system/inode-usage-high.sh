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

# long_name: Check for high inode usage
# description: Check if inode usage is above critical thresholds on any filesystem
# priority: 400

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

# Set thresholds
INODE_WARNING_THRESHOLD=80
INODE_CRITICAL_THRESHOLD=95

ISSUES_FOUND=0

if [[ "x$RISU_LIVE" == "x1" ]]; then
    # Get current inode usage
    if command -v df >/dev/null 2>&1; then
        # Get inode usage for all mounted filesystems
        while IFS= read -r line; do
            # Skip header and special filesystems
            [[ $line =~ ^Filesystem ]] && continue
            [[ $line =~ ^tmpfs ]] && continue
            [[ $line =~ ^devtmpfs ]] && continue
            [[ $line =~ ^/dev/loop ]] && continue
            [[ $line =~ ^udev ]] && continue

            USAGE=$(echo "$line" | awk '{print $5}' | tr -d '%')
            FILESYSTEM=$(echo "$line" | awk '{print $1}')
            MOUNTPOINT=$(echo "$line" | awk '{print $6}')

            if [[ $USAGE =~ ^[0-9]+$ ]]; then
                if [[ $USAGE -ge $INODE_CRITICAL_THRESHOLD ]]; then
                    echo "CRITICAL: Inode usage on $FILESYSTEM ($MOUNTPOINT) is ${USAGE}% (threshold: ${INODE_CRITICAL_THRESHOLD}%)" >&2
                    ISSUES_FOUND=1
                elif [[ $USAGE -ge $INODE_WARNING_THRESHOLD ]]; then
                    echo "WARNING: Inode usage on $FILESYSTEM ($MOUNTPOINT) is ${USAGE}% (threshold: ${INODE_WARNING_THRESHOLD}%)" >&2
                    ISSUES_FOUND=1
                fi
            fi
        done < <(df -i | grep -v "^Filesystem")
    else
        echo "df command not available" >&2
        exit $RC_SKIPPED
    fi
else
    # Check sosreport for inode usage
    if [[ -f "${RISU_ROOT}/df_-i" ]]; then
        while IFS= read -r line; do
            # Skip header and special filesystems
            [[ $line =~ ^Filesystem ]] && continue
            [[ $line =~ ^tmpfs ]] && continue
            [[ $line =~ ^devtmpfs ]] && continue
            [[ $line =~ ^/dev/loop ]] && continue
            [[ $line =~ ^udev ]] && continue

            USAGE=$(echo "$line" | awk '{print $5}' | tr -d '%')
            FILESYSTEM=$(echo "$line" | awk '{print $1}')
            MOUNTPOINT=$(echo "$line" | awk '{print $6}')

            if [[ $USAGE =~ ^[0-9]+$ ]]; then
                if [[ $USAGE -ge $INODE_CRITICAL_THRESHOLD ]]; then
                    echo "CRITICAL: Inode usage on $FILESYSTEM ($MOUNTPOINT) was ${USAGE}% (threshold: ${INODE_CRITICAL_THRESHOLD}%)" >&2
                    ISSUES_FOUND=1
                elif [[ $USAGE -ge $INODE_WARNING_THRESHOLD ]]; then
                    echo "WARNING: Inode usage on $FILESYSTEM ($MOUNTPOINT) was ${USAGE}% (threshold: ${INODE_WARNING_THRESHOLD}%)" >&2
                    ISSUES_FOUND=1
                fi
            fi
        done <"${RISU_ROOT}/df_-i"
    else
        echo "df -i file not found in sosreport" >&2
        exit $RC_SKIPPED
    fi
fi

if [[ $ISSUES_FOUND -eq 1 ]]; then
    exit $RC_FAILED
else
    echo "All inode usage levels are within acceptable thresholds" >&2
    exit $RC_OKAY
fi
