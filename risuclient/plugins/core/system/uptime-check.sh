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

# long_name: Check system uptime
# description: Check system uptime and recent reboots
# priority: 830

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

UPTIME_ISSUES=0

if [[ "x$RISU_LIVE" == "x1" ]]; then
    # Check current uptime
    if [[ -f "/proc/uptime" ]]; then
        UPTIME_SECONDS=$(cat /proc/uptime | awk '{print $1}' | cut -d. -f1)
        UPTIME_HOURS=$((UPTIME_SECONDS / 3600))
        UPTIME_DAYS=$((UPTIME_HOURS / 24))

        if [[ $UPTIME_HOURS -lt 1 ]]; then
            echo "WARNING: System uptime is very low: ${UPTIME_HOURS} hours" >&2
            UPTIME_ISSUES=$((UPTIME_ISSUES + 1))
        elif [[ $UPTIME_DAYS -gt 365 ]]; then
            echo "WARNING: System uptime is very high: ${UPTIME_DAYS} days (may need reboot for updates)" >&2
            UPTIME_ISSUES=$((UPTIME_ISSUES + 1))
        fi
    fi

    # Check for recent reboots in logs
    if command -v last >/dev/null 2>&1; then
        RECENT_REBOOTS=$(last reboot | head -5 | grep -c "reboot" || echo "0")
        if [[ $RECENT_REBOOTS -gt 3 ]]; then
            echo "WARNING: Multiple recent reboots detected ($RECENT_REBOOTS)" >&2
            UPTIME_ISSUES=$((UPTIME_ISSUES + 1))
        fi
    fi

    # Check for unexpected reboots
    if command -v journalctl >/dev/null 2>&1; then
        UNEXPECTED_REBOOTS=$(journalctl --since "7 days ago" | grep -c "Kernel panic\|watchdog\|emergency" || echo "0")
        if [[ $UNEXPECTED_REBOOTS -gt 0 ]]; then
            echo "WARNING: Found $UNEXPECTED_REBOOTS unexpected reboot events in journal" >&2
            UPTIME_ISSUES=$((UPTIME_ISSUES + UNEXPECTED_REBOOTS))
        fi
    fi
else
    # Check sosreport for uptime
    if [[ -f "${RISU_ROOT}/proc/uptime" ]]; then
        UPTIME_SECONDS=$(cat "${RISU_ROOT}/proc/uptime" | awk '{print $1}' | cut -d. -f1)
        UPTIME_HOURS=$((UPTIME_SECONDS / 3600))
        UPTIME_DAYS=$((UPTIME_HOURS / 24))

        if [[ $UPTIME_HOURS -lt 1 ]]; then
            echo "WARNING: System uptime was very low: ${UPTIME_HOURS} hours" >&2
            UPTIME_ISSUES=$((UPTIME_ISSUES + 1))
        elif [[ $UPTIME_DAYS -gt 365 ]]; then
            echo "WARNING: System uptime was very high: ${UPTIME_DAYS} days (may need reboot for updates)" >&2
            UPTIME_ISSUES=$((UPTIME_ISSUES + 1))
        fi
    fi

    # Check for recent reboots in sosreport
    if [[ -f "${RISU_ROOT}/last_reboot" ]]; then
        RECENT_REBOOTS=$(head -5 "${RISU_ROOT}/last_reboot" | grep -c "reboot" || echo "0")
        if [[ $RECENT_REBOOTS -gt 3 ]]; then
            echo "WARNING: Multiple recent reboots detected ($RECENT_REBOOTS)" >&2
            UPTIME_ISSUES=$((UPTIME_ISSUES + 1))
        fi
    fi

    # Check for unexpected reboots in sosreport
    if [[ -f "${RISU_ROOT}/journalctl" ]]; then
        UNEXPECTED_REBOOTS=$(grep -c "Kernel panic\|watchdog\|emergency" "${RISU_ROOT}/journalctl" || echo "0")
        if [[ $UNEXPECTED_REBOOTS -gt 0 ]]; then
            echo "WARNING: Found $UNEXPECTED_REBOOTS unexpected reboot events in journal" >&2
            UPTIME_ISSUES=$((UPTIME_ISSUES + UNEXPECTED_REBOOTS))
        fi
    fi
fi

# Check results
if [[ $UPTIME_ISSUES -gt 3 ]]; then
    echo "CRITICAL: Multiple uptime issues found ($UPTIME_ISSUES)" >&2
    exit $RC_FAILED
elif [[ $UPTIME_ISSUES -gt 1 ]]; then
    echo "WARNING: Uptime issues found ($UPTIME_ISSUES)" >&2
    exit $RC_FAILED
elif [[ $UPTIME_ISSUES -gt 0 ]]; then
    echo "INFO: Minor uptime issues found ($UPTIME_ISSUES)" >&2
    exit $RC_OKAY
else
    echo "System uptime appears to be healthy" >&2
    exit $RC_OKAY
fi
