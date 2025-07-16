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

# long_name: Check cron jobs status
# description: Check cron daemon and job configuration
# priority: 400

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

CRON_ISSUES=0

if [[ "x$RISU_LIVE" == "x1" ]]; then
    # Check crond service
    if command -v systemctl >/dev/null 2>&1; then
        CROND_STATUS=$(systemctl is-active crond 2>/dev/null || echo "inactive")
        if [[ $CROND_STATUS != "active" ]]; then
            echo "WARNING: crond service is not active ($CROND_STATUS)" >&2
            CRON_ISSUES=$((CRON_ISSUES + 1))
        fi
    fi

    # Check cron configuration files
    if [[ -f "/etc/crontab" ]]; then
        # Check for syntax errors in crontab
        if grep -q "^[^#]*[[:space:]]*[*0-9][[:space:]]*[*0-9][[:space:]]*[*0-9][[:space:]]*[*0-9][[:space:]]*[*0-7]" /etc/crontab; then
            echo "INFO: System crontab appears to have valid entries" >&2
        else
            echo "WARNING: System crontab may have syntax issues" >&2
            CRON_ISSUES=$((CRON_ISSUES + 1))
        fi
    fi

    # Check for cron jobs in /etc/cron.d/
    if [[ -d "/etc/cron.d" ]]; then
        CRON_D_FILES=$(find /etc/cron.d -type f 2>/dev/null | wc -l)
        if [[ $CRON_D_FILES -gt 0 ]]; then
            echo "INFO: Found $CRON_D_FILES cron job files in /etc/cron.d/" >&2
        fi
    fi

    # Check for failed cron jobs in logs
    if [[ -f "/var/log/cron" ]]; then
        FAILED_JOBS=$(tail -100 /var/log/cron | grep -c "FAILED\|ERROR\|can't" || echo "0")
        if [[ $FAILED_JOBS -gt 5 ]]; then
            echo "WARNING: Found $FAILED_JOBS failed cron jobs in recent logs" >&2
            CRON_ISSUES=$((CRON_ISSUES + 1))
        fi
    fi

    # Check user crontabs
    if command -v crontab >/dev/null 2>&1; then
        if crontab -l >/dev/null 2>&1; then
            echo "INFO: User crontab is configured" >&2
        fi
    fi
else
    # Check sosreport for cron information
    if [[ -f "${RISU_ROOT}/systemctl_is-active_crond" ]]; then
        CROND_STATUS=$(cat "${RISU_ROOT}/systemctl_is-active_crond" 2>/dev/null || echo "inactive")
        if [[ $CROND_STATUS != "active" ]]; then
            echo "WARNING: crond service was not active ($CROND_STATUS)" >&2
            CRON_ISSUES=$((CRON_ISSUES + 1))
        fi
    fi

    # Check cron configuration files in sosreport
    if [[ -f "${RISU_ROOT}/etc/crontab" ]]; then
        # Check for syntax errors in crontab
        if grep -q "^[^#]*[[:space:]]*[*0-9][[:space:]]*[*0-9][[:space:]]*[*0-9][[:space:]]*[*0-9][[:space:]]*[*0-7]" "${RISU_ROOT}/etc/crontab"; then
            echo "INFO: System crontab appeared to have valid entries" >&2
        else
            echo "WARNING: System crontab may have had syntax issues" >&2
            CRON_ISSUES=$((CRON_ISSUES + 1))
        fi
    fi

    # Check for failed cron jobs in sosreport logs
    if [[ -f "${RISU_ROOT}/var/log/cron" ]]; then
        FAILED_JOBS=$(tail -100 "${RISU_ROOT}/var/log/cron" | grep -c "FAILED\|ERROR\|can't" || echo "0")
        if [[ $FAILED_JOBS -gt 5 ]]; then
            echo "WARNING: Found $FAILED_JOBS failed cron jobs in logs" >&2
            CRON_ISSUES=$((CRON_ISSUES + 1))
        fi
    fi
fi

# Check results
if [[ $CRON_ISSUES -gt 3 ]]; then
    echo "CRITICAL: Multiple cron issues found ($CRON_ISSUES)" >&2
    exit $RC_FAILED
elif [[ $CRON_ISSUES -gt 1 ]]; then
    echo "WARNING: Cron issues found ($CRON_ISSUES)" >&2
    exit $RC_FAILED
elif [[ $CRON_ISSUES -gt 0 ]]; then
    echo "INFO: Minor cron issues found ($CRON_ISSUES)" >&2
    exit $RC_OKAY
else
    echo "Cron configuration appears to be healthy" >&2
    exit $RC_OKAY
fi
