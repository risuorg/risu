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

# long_name: Check kernel modules
# description: Check kernel modules for issues
# priority: 910

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

MODULE_ISSUES=0

if [[ "x$RISU_LIVE" == "x1" ]]; then
    # Check for tainted kernel
    if [[ -f "/proc/sys/kernel/tainted" ]]; then
        TAINTED=$(cat /proc/sys/kernel/tainted)
        if [[ $TAINTED -ne 0 ]]; then
            echo "WARNING: Kernel is tainted (value: $TAINTED)" >&2
            MODULE_ISSUES=$((MODULE_ISSUES + 1))
        fi
    fi

    # Check for failed module loads
    if command -v dmesg >/dev/null 2>&1; then
        FAILED_MODULES=$(dmesg -T 2>/dev/null | grep -ci "module.*failed\|insmod.*failed\|modprobe.*failed" || echo "0")
        if [[ $FAILED_MODULES -gt 0 ]]; then
            echo "WARNING: Found $FAILED_MODULES failed module loads in dmesg" >&2
            MODULE_ISSUES=$((MODULE_ISSUES + FAILED_MODULES))
        fi
    fi

    # Check for unsigned modules
    if command -v lsmod >/dev/null 2>&1; then
        UNSIGNED_MODULES=$(lsmod | grep -c "unsigned" || echo "0")
        if [[ $UNSIGNED_MODULES -gt 0 ]]; then
            echo "WARNING: Found $UNSIGNED_MODULES unsigned modules loaded" >&2
            MODULE_ISSUES=$((MODULE_ISSUES + 1))
        fi
    fi

    # Check for blacklisted modules that are loaded
    if [[ -f "/etc/modprobe.d/blacklist.conf" ]]; then
        BLACKLISTED_LOADED=0
        while IFS= read -r line; do
            if [[ $line =~ ^blacklist[[:space:]]+(.+)$ ]]; then
                MODULE="${BASH_REMATCH[1]}"
                if lsmod | grep -q "^$MODULE "; then
                    echo "WARNING: Blacklisted module $MODULE is loaded" >&2
                    BLACKLISTED_LOADED=$((BLACKLISTED_LOADED + 1))
                fi
            fi
        done <"/etc/modprobe.d/blacklist.conf"
        MODULE_ISSUES=$((MODULE_ISSUES + BLACKLISTED_LOADED))
    fi
else
    # Check sosreport for kernel modules
    if [[ -f "${RISU_ROOT}/proc/sys/kernel/tainted" ]]; then
        TAINTED=$(cat "${RISU_ROOT}/proc/sys/kernel/tainted")
        if [[ $TAINTED -ne 0 ]]; then
            echo "WARNING: Kernel was tainted (value: $TAINTED)" >&2
            MODULE_ISSUES=$((MODULE_ISSUES + 1))
        fi
    fi

    # Check for failed module loads in sosreport
    if [[ -f "${RISU_ROOT}/dmesg" ]]; then
        FAILED_MODULES=$(grep -ci "module.*failed\|insmod.*failed\|modprobe.*failed" "${RISU_ROOT}/dmesg" || echo "0")
        if [[ $FAILED_MODULES -gt 0 ]]; then
            echo "WARNING: Found $FAILED_MODULES failed module loads in dmesg" >&2
            MODULE_ISSUES=$((MODULE_ISSUES + FAILED_MODULES))
        fi
    fi

    # Check for unsigned modules in sosreport
    if [[ -f "${RISU_ROOT}/lsmod" ]]; then
        UNSIGNED_MODULES=$(grep -c "unsigned" "${RISU_ROOT}/lsmod" || echo "0")
        if [[ $UNSIGNED_MODULES -gt 0 ]]; then
            echo "WARNING: Found $UNSIGNED_MODULES unsigned modules loaded" >&2
            MODULE_ISSUES=$((MODULE_ISSUES + 1))
        fi
    fi
fi

# Check results
if [[ $MODULE_ISSUES -gt 5 ]]; then
    echo "CRITICAL: Multiple kernel module issues found ($MODULE_ISSUES)" >&2
    exit $RC_FAILED
elif [[ $MODULE_ISSUES -gt 2 ]]; then
    echo "WARNING: Kernel module issues found ($MODULE_ISSUES)" >&2
    exit $RC_FAILED
elif [[ $MODULE_ISSUES -gt 0 ]]; then
    echo "INFO: Minor kernel module issues found ($MODULE_ISSUES)" >&2
    exit $RC_OKAY
else
    echo "Kernel modules appear to be healthy" >&2
    exit $RC_OKAY
fi
