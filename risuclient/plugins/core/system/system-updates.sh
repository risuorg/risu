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

# long_name: Check system updates
# description: Check for available system updates
# priority: 400

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

UPDATE_ISSUES=0

if [[ "x$RISU_LIVE" == "x1" ]]; then
    # Check for available updates
    if command -v yum >/dev/null 2>&1; then
        AVAILABLE_UPDATES=$(yum check-update 2>/dev/null | grep -c "^[[:alnum:]]" || echo "0")
        if [[ $AVAILABLE_UPDATES -gt 50 ]]; then
            echo "WARNING: $AVAILABLE_UPDATES updates available (threshold: 50)" >&2
            UPDATE_ISSUES=$((UPDATE_ISSUES + 1))
        elif [[ $AVAILABLE_UPDATES -gt 20 ]]; then
            echo "INFO: $AVAILABLE_UPDATES updates available" >&2
        fi
    elif command -v dnf >/dev/null 2>&1; then
        AVAILABLE_UPDATES=$(dnf check-update 2>/dev/null | grep -c "^[[:alnum:]]" || echo "0")
        if [[ $AVAILABLE_UPDATES -gt 50 ]]; then
            echo "WARNING: $AVAILABLE_UPDATES updates available (threshold: 50)" >&2
            UPDATE_ISSUES=$((UPDATE_ISSUES + 1))
        elif [[ $AVAILABLE_UPDATES -gt 20 ]]; then
            echo "INFO: $AVAILABLE_UPDATES updates available" >&2
        fi
    elif command -v apt >/dev/null 2>&1; then
        AVAILABLE_UPDATES=$(apt list --upgradable 2>/dev/null | grep -c "upgradable" || echo "0")
        if [[ $AVAILABLE_UPDATES -gt 50 ]]; then
            echo "WARNING: $AVAILABLE_UPDATES updates available (threshold: 50)" >&2
            UPDATE_ISSUES=$((UPDATE_ISSUES + 1))
        elif [[ $AVAILABLE_UPDATES -gt 20 ]]; then
            echo "INFO: $AVAILABLE_UPDATES updates available" >&2
        fi
    fi

    # Check for security updates
    if command -v yum >/dev/null 2>&1; then
        SECURITY_UPDATES=$(yum --security check-update 2>/dev/null | grep -c "^[[:alnum:]]" || echo "0")
        if [[ $SECURITY_UPDATES -gt 0 ]]; then
            echo "WARNING: $SECURITY_UPDATES security updates available" >&2
            UPDATE_ISSUES=$((UPDATE_ISSUES + SECURITY_UPDATES))
        fi
    fi

    # Check last update time
    if [[ -f "/var/log/yum.log" ]]; then
        LAST_UPDATE=$(tail -1 /var/log/yum.log | grep "Updated:" | head -1 | awk '{print $1, $2}')
        if [[ -n $LAST_UPDATE ]]; then
            LAST_UPDATE_DATE=$(date -d "$LAST_UPDATE" +%s 2>/dev/null || echo "0")
            CURRENT_DATE=$(date +%s)
            DAYS_SINCE_UPDATE=$(((CURRENT_DATE - LAST_UPDATE_DATE) / 86400))

            if [[ $DAYS_SINCE_UPDATE -gt 90 ]]; then
                echo "WARNING: Last update was $DAYS_SINCE_UPDATE days ago" >&2
                UPDATE_ISSUES=$((UPDATE_ISSUES + 1))
            fi
        fi
    fi
else
    # Check sosreport for update information
    if [[ -f "${RISU_ROOT}/yum_check-update" ]]; then
        AVAILABLE_UPDATES=$(grep -c "^[[:alnum:]]" "${RISU_ROOT}/yum_check-update" || echo "0")
        if [[ $AVAILABLE_UPDATES -gt 50 ]]; then
            echo "WARNING: $AVAILABLE_UPDATES updates were available (threshold: 50)" >&2
            UPDATE_ISSUES=$((UPDATE_ISSUES + 1))
        elif [[ $AVAILABLE_UPDATES -gt 20 ]]; then
            echo "INFO: $AVAILABLE_UPDATES updates were available" >&2
        fi
    fi

    # Check security updates in sosreport
    if [[ -f "${RISU_ROOT}/yum_--security_check-update" ]]; then
        SECURITY_UPDATES=$(grep -c "^[[:alnum:]]" "${RISU_ROOT}/yum_--security_check-update" || echo "0")
        if [[ $SECURITY_UPDATES -gt 0 ]]; then
            echo "WARNING: $SECURITY_UPDATES security updates were available" >&2
            UPDATE_ISSUES=$((UPDATE_ISSUES + SECURITY_UPDATES))
        fi
    fi

    # Check last update time in sosreport
    if [[ -f "${RISU_ROOT}/var/log/yum.log" ]]; then
        LAST_UPDATE=$(tail -1 "${RISU_ROOT}/var/log/yum.log" | grep "Updated:" | head -1 | awk '{print $1, $2}')
        if [[ -n $LAST_UPDATE ]]; then
            LAST_UPDATE_DATE=$(date -d "$LAST_UPDATE" +%s 2>/dev/null || echo "0")
            SOSREPORT_DATE=$(stat -c %Y "${RISU_ROOT}/var/log/yum.log" 2>/dev/null || date +%s)
            DAYS_SINCE_UPDATE=$(((SOSREPORT_DATE - LAST_UPDATE_DATE) / 86400))

            if [[ $DAYS_SINCE_UPDATE -gt 90 ]]; then
                echo "WARNING: Last update was $DAYS_SINCE_UPDATE days before sosreport" >&2
                UPDATE_ISSUES=$((UPDATE_ISSUES + 1))
            fi
        fi
    fi
fi

# Check results
if [[ $UPDATE_ISSUES -gt 10 ]]; then
    echo "CRITICAL: Multiple update issues found ($UPDATE_ISSUES)" >&2
    exit $RC_FAILED
elif [[ $UPDATE_ISSUES -gt 5 ]]; then
    echo "WARNING: Update issues found ($UPDATE_ISSUES)" >&2
    exit $RC_FAILED
elif [[ $UPDATE_ISSUES -gt 0 ]]; then
    echo "INFO: Minor update issues found ($UPDATE_ISSUES)" >&2
    exit $RC_OKAY
else
    echo "System updates appear to be current" >&2
    exit $RC_OKAY
fi
