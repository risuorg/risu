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

# long_name: Check I/O performance
# description: Check for I/O performance issues
# priority: 280

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

IO_ISSUES=0

if [[ "x$RISU_LIVE" == "x1" ]]; then
    # Check I/O wait time
    if [[ -f "/proc/stat" ]]; then
        IOWAIT=$(grep "^cpu " /proc/stat | awk '{print $6}')
        if [[ $IOWAIT -gt 1000 ]]; then
            echo "WARNING: High I/O wait time detected: $IOWAIT" >&2
            IO_ISSUES=$((IO_ISSUES + 1))
        fi
    fi

    # Check for high disk utilization
    if command -v iostat >/dev/null 2>&1; then
        HIGH_UTIL=$(iostat -x 1 1 | tail -n +4 | awk '$10 > 80 {print $1, $10}' | wc -l)
        if [[ $HIGH_UTIL -gt 0 ]]; then
            echo "WARNING: Found $HIGH_UTIL devices with high utilization:" >&2
            iostat -x 1 1 | tail -n +4 | awk '$10 > 80 {print $1, $10}' >&2
            IO_ISSUES=$((IO_ISSUES + HIGH_UTIL))
        fi
    fi

    # Check for blocked processes
    if [[ -f "/proc/stat" ]]; then
        BLOCKED_PROCS=$(grep "^procs_blocked" /proc/stat | awk '{print $2}')
        if [[ $BLOCKED_PROCS -gt 5 ]]; then
            echo "WARNING: High number of blocked processes: $BLOCKED_PROCS" >&2
            IO_ISSUES=$((IO_ISSUES + 1))
        fi
    fi

    # Check for disk errors in dmesg
    if command -v dmesg >/dev/null 2>&1; then
        DISK_ERRORS=$(dmesg -T 2>/dev/null | grep -ci "I/O error\|ata.*error\|scsi.*error\|sd.*error" || echo "0")
        if [[ $DISK_ERRORS -gt 0 ]]; then
            echo "WARNING: Found $DISK_ERRORS disk I/O errors in dmesg" >&2
            IO_ISSUES=$((IO_ISSUES + DISK_ERRORS))
        fi
    fi
else
    # Check sosreport for I/O performance
    if [[ -f "${RISU_ROOT}/proc/stat" ]]; then
        IOWAIT=$(grep "^cpu " "${RISU_ROOT}/proc/stat" | awk '{print $6}')
        if [[ $IOWAIT -gt 1000 ]]; then
            echo "WARNING: High I/O wait time detected: $IOWAIT" >&2
            IO_ISSUES=$((IO_ISSUES + 1))
        fi

        BLOCKED_PROCS=$(grep "^procs_blocked" "${RISU_ROOT}/proc/stat" | awk '{print $2}')
        if [[ $BLOCKED_PROCS -gt 5 ]]; then
            echo "WARNING: High number of blocked processes: $BLOCKED_PROCS" >&2
            IO_ISSUES=$((IO_ISSUES + 1))
        fi
    fi

    # Check for high disk utilization in sosreport
    if [[ -f "${RISU_ROOT}/iostat" ]]; then
        HIGH_UTIL=$(tail -n +4 "${RISU_ROOT}/iostat" | awk '$10 > 80 {print $1, $10}' | wc -l)
        if [[ $HIGH_UTIL -gt 0 ]]; then
            echo "WARNING: Found $HIGH_UTIL devices with high utilization:" >&2
            tail -n +4 "${RISU_ROOT}/iostat" | awk '$10 > 80 {print $1, $10}' >&2
            IO_ISSUES=$((IO_ISSUES + HIGH_UTIL))
        fi
    fi

    # Check for disk errors in sosreport
    if [[ -f "${RISU_ROOT}/dmesg" ]]; then
        DISK_ERRORS=$(grep -ci "I/O error\|ata.*error\|scsi.*error\|sd.*error" "${RISU_ROOT}/dmesg" || echo "0")
        if [[ $DISK_ERRORS -gt 0 ]]; then
            echo "WARNING: Found $DISK_ERRORS disk I/O errors in dmesg" >&2
            IO_ISSUES=$((IO_ISSUES + DISK_ERRORS))
        fi
    fi
fi

# Check results
if [[ $IO_ISSUES -gt 5 ]]; then
    echo "CRITICAL: Multiple I/O performance issues found ($IO_ISSUES)" >&2
    exit $RC_FAILED
elif [[ $IO_ISSUES -gt 2 ]]; then
    echo "WARNING: I/O performance issues found ($IO_ISSUES)" >&2
    exit $RC_FAILED
elif [[ $IO_ISSUES -gt 0 ]]; then
    echo "INFO: Minor I/O performance issues found ($IO_ISSUES)" >&2
    exit $RC_OKAY
else
    echo "I/O performance appears to be adequate" >&2
    exit $RC_OKAY
fi
