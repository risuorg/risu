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

# long_name: Check for disk space usage
# description: Check if disk usage is above critical thresholds on any filesystem
# priority: 940

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

# Set thresholds
DISK_WARNING_THRESHOLD=85
DISK_CRITICAL_THRESHOLD=95

ISSUES_FOUND=0

if [[ "x$RISU_LIVE" == "x1" ]]; then
    # Get current disk usage with filesystem type information
    if command -v df >/dev/null 2>&1; then
        # Get disk usage for all mounted filesystems with type information
        while IFS= read -r line; do
            # Skip header and special filesystems
            [[ $line =~ ^Filesystem ]] && continue
            [[ $line =~ ^tmpfs ]] && continue
            [[ $line =~ ^devtmpfs ]] && continue
            [[ $line =~ ^/dev/loop ]] && continue
            [[ $line =~ ^udev ]] && continue

            FILESYSTEM=$(echo "$line" | awk '{print $1}')
            FSTYPE=$(echo "$line" | awk '{print $2}')
            USAGE=$(echo "$line" | awk '{print $6}' | tr -d '%')
            MOUNTPOINT=$(echo "$line" | awk '{print $7}')

            # Skip optical media filesystems (DVDs/CDs) and devices
            case "$FSTYPE" in
            "iso9660" | "udf")
                continue
                ;;
            esac

            # Skip optical drive devices
            case "$FILESYSTEM" in
            /dev/sr* | /dev/cdrom* | /dev/dvd*)
                continue
                ;;
            esac

            if [[ $USAGE =~ ^[0-9]+$ ]]; then
                if [[ $USAGE -ge $DISK_CRITICAL_THRESHOLD ]]; then
                    echo "CRITICAL: Disk usage on $FILESYSTEM ($MOUNTPOINT) is ${USAGE}% (threshold: ${DISK_CRITICAL_THRESHOLD}%)" >&2
                    ISSUES_FOUND=1
                elif [[ $USAGE -ge $DISK_WARNING_THRESHOLD ]]; then
                    echo "WARNING: Disk usage on $FILESYSTEM ($MOUNTPOINT) is ${USAGE}% (threshold: ${DISK_WARNING_THRESHOLD}%)" >&2
                    ISSUES_FOUND=1
                fi
            fi
        done < <(df -T | grep -v "^Filesystem")
    else
        echo "df command not available" >&2
        exit $RC_SKIPPED
    fi
else
    # Check sosreport for disk usage
    if [[ -f "${RISU_ROOT}/df" ]]; then
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

            # Skip optical drive devices in sosreport mode
            case "$FILESYSTEM" in
            /dev/sr* | /dev/cdrom* | /dev/dvd*)
                continue
                ;;
            esac

            if [[ $USAGE =~ ^[0-9]+$ ]]; then
                if [[ $USAGE -ge $DISK_CRITICAL_THRESHOLD ]]; then
                    echo "CRITICAL: Disk usage on $FILESYSTEM ($MOUNTPOINT) was ${USAGE}% (threshold: ${DISK_CRITICAL_THRESHOLD}%)" >&2
                    ISSUES_FOUND=1
                elif [[ $USAGE -ge $DISK_WARNING_THRESHOLD ]]; then
                    echo "WARNING: Disk usage on $FILESYSTEM ($MOUNTPOINT) was ${USAGE}% (threshold: ${DISK_WARNING_THRESHOLD}%)" >&2
                    ISSUES_FOUND=1
                fi
            fi
        done <"${RISU_ROOT}/df"
    else
        echo "df file not found in sosreport" >&2
        exit $RC_SKIPPED
    fi
fi

if [[ $ISSUES_FOUND -eq 1 ]]; then
    exit $RC_FAILED
else
    echo "All disk usage levels are within acceptable thresholds" >&2
    exit $RC_OKAY
fi
