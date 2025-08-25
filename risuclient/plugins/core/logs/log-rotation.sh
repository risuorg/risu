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

# long_name: Check log rotation configuration
# description: Check log rotation configuration and status
# priority: 400

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

LOG_ISSUES=0

if [[ "x$RISU_LIVE" == "x1" ]]; then
    # Check logrotate configuration
    if [[ -f "/etc/logrotate.conf" ]]; then
        # Check if logrotate is configured properly
        if ! grep -q "rotate" /etc/logrotate.conf; then
            echo "WARNING: No rotate directive found in /etc/logrotate.conf" >&2
            LOG_ISSUES=$((LOG_ISSUES + 1))
        fi

        # Check if compression is enabled
        if ! grep -q "compress" /etc/logrotate.conf; then
            echo "WARNING: Log compression not enabled in /etc/logrotate.conf" >&2
            LOG_ISSUES=$((LOG_ISSUES + 1))
        fi
    else
        echo "WARNING: /etc/logrotate.conf not found" >&2
        LOG_ISSUES=$((LOG_ISSUES + 1))
    fi

    # Check logrotate service
    if systemctl is-active logrotate.timer >/dev/null 2>&1; then
        echo "INFO: logrotate.timer is active" >&2
    else
        echo "WARNING: logrotate.timer is not active" >&2
        LOG_ISSUES=$((LOG_ISSUES + 1))
    fi

    # Check for large log files
    LARGE_LOGS=$(find /var/log -type f -size +100M 2>/dev/null | wc -l)
    if [[ $LARGE_LOGS -gt 0 ]]; then
        echo "WARNING: Found $LARGE_LOGS log files larger than 100MB:" >&2
        find /var/log -type f -size +100M 2>/dev/null | head -5 >&2
        LOG_ISSUES=$((LOG_ISSUES + 1))
    fi

    # Check /var/log disk usage
    VAR_LOG_USAGE=$(df /var/log 2>/dev/null | tail -1 | awk '{print $5}' | tr -d '%')
    if [[ $VAR_LOG_USAGE -gt 80 ]]; then
        echo "WARNING: /var/log disk usage is high: ${VAR_LOG_USAGE}%" >&2
        LOG_ISSUES=$((LOG_ISSUES + 1))
    fi
else
    # Check sosreport for log rotation configuration
    if [[ -f "${RISU_ROOT}/etc/logrotate.conf" ]]; then
        # Check if logrotate is configured properly
        if ! grep -q "rotate" "${RISU_ROOT}/etc/logrotate.conf"; then
            echo "WARNING: No rotate directive found in /etc/logrotate.conf" >&2
            LOG_ISSUES=$((LOG_ISSUES + 1))
        fi

        # Check if compression is enabled
        if ! grep -q "compress" "${RISU_ROOT}/etc/logrotate.conf"; then
            echo "WARNING: Log compression not enabled in /etc/logrotate.conf" >&2
            LOG_ISSUES=$((LOG_ISSUES + 1))
        fi
    else
        echo "WARNING: /etc/logrotate.conf not found in sosreport" >&2
        LOG_ISSUES=$((LOG_ISSUES + 1))
    fi

    # Check for large log files in sosreport
    if [[ -f "${RISU_ROOT}/find_var_log_-size_+100M" ]]; then
        LARGE_LOGS=$(wc -l <"${RISU_ROOT}/find_var_log_-size_+100M")
        if [[ $LARGE_LOGS -gt 0 ]]; then
            echo "WARNING: Found $LARGE_LOGS log files larger than 100MB:" >&2
            head -5 "${RISU_ROOT}/find_var_log_-size_+100M" >&2
            LOG_ISSUES=$((LOG_ISSUES + 1))
        fi
    fi

    # Check /var/log disk usage in sosreport
    if [[ -f "${RISU_ROOT}/df" ]]; then
        VAR_LOG_USAGE=$(grep "/var/log" "${RISU_ROOT}/df" | awk '{print $5}' | tr -d '%')
        if [[ -n $VAR_LOG_USAGE && $VAR_LOG_USAGE -gt 80 ]]; then
            echo "WARNING: /var/log disk usage was high: ${VAR_LOG_USAGE}%" >&2
            LOG_ISSUES=$((LOG_ISSUES + 1))
        fi
    fi
fi

# Check results
if [[ $LOG_ISSUES -gt 3 ]]; then
    echo "CRITICAL: Multiple log rotation issues found ($LOG_ISSUES)" >&2
    exit $RC_FAILED
elif [[ $LOG_ISSUES -gt 1 ]]; then
    echo "WARNING: Log rotation issues found ($LOG_ISSUES)" >&2
    exit $RC_FAILED
elif [[ $LOG_ISSUES -gt 0 ]]; then
    echo "INFO: Minor log rotation issues found ($LOG_ISSUES)" >&2
    exit $RC_OKAY
else
    echo "Log rotation configuration appears to be adequate" >&2
    exit $RC_OKAY
fi
