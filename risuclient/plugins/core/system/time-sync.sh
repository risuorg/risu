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

# long_name: Check time synchronization
# description: Check if time synchronization is working properly
# priority: 830

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

TIME_ISSUES=0

if [[ "x$RISU_LIVE" == "x1" ]]; then
    # Check if chrony is running
    if is_active chronyd; then
        echo "INFO: chronyd service is running" >&2

        # Check chrony synchronization status
        if command -v chronyc >/dev/null 2>&1; then
            # Check if chrony is synchronized
            if chronyc tracking | grep -q "Leap status.*Normal"; then
                echo "INFO: chronyd is synchronized" >&2
            else
                echo "WARNING: chronyd is not synchronized" >&2
                TIME_ISSUES=$((TIME_ISSUES + 1))
            fi
        fi
    else
        echo "INFO: chronyd service is not running, checking ntpd" >&2

        # Check if ntpd is running
        if is_active ntpd; then
            echo "INFO: ntpd service is running" >&2

            # Check ntpd synchronization status
            if command -v ntpstat >/dev/null 2>&1; then
                if ntpstat >/dev/null 2>&1; then
                    echo "INFO: ntpd is synchronized" >&2
                else
                    echo "WARNING: ntpd is not synchronized" >&2
                    TIME_ISSUES=$((TIME_ISSUES + 1))
                fi
            fi
        else
            echo "WARNING: Neither chronyd nor ntpd is running" >&2
            TIME_ISSUES=$((TIME_ISSUES + 1))
        fi
    fi

    # Check if timedatectl shows NTP synchronization
    if command -v timedatectl >/dev/null 2>&1; then
        NTP_SYNC=$(timedatectl status | grep "NTP synchronized" | awk '{print $3}')
        if [[ $NTP_SYNC != "yes" ]]; then
            echo "WARNING: NTP synchronization is not enabled" >&2
            TIME_ISSUES=$((TIME_ISSUES + 1))
        fi
    fi
else
    # Check sosreport for time synchronization
    if [[ -f "${RISU_ROOT}/systemctl_is-active_chronyd" ]]; then
        CHRONYD_STATUS=$(cat "${RISU_ROOT}/systemctl_is-active_chronyd" 2>/dev/null || echo "inactive")
        if [[ $CHRONYD_STATUS != "active" ]]; then
            echo "WARNING: chronyd service was not active ($CHRONYD_STATUS)" >&2
            TIME_ISSUES=$((TIME_ISSUES + 1))
        fi
    fi

    # Check chrony sources in sosreport
    if [[ -f "${RISU_ROOT}/chronyc_sources" ]]; then
        SOURCES=$(grep -c "^\^\*" "${RISU_ROOT}/chronyc_sources" || echo "0")
        if [[ $SOURCES -eq 0 ]]; then
            echo "WARNING: No synchronized chrony sources were found" >&2
            TIME_ISSUES=$((TIME_ISSUES + 1))
        fi
    fi

    # Check timedatectl in sosreport
    if [[ -f "${RISU_ROOT}/timedatectl" ]]; then
        NTP_SYNC=$(grep "NTP synchronized" "${RISU_ROOT}/timedatectl" | awk '{print $3}')
        if [[ $NTP_SYNC != "yes" ]]; then
            echo "WARNING: NTP synchronization was not enabled" >&2
            TIME_ISSUES=$((TIME_ISSUES + 1))
        fi
    fi
fi

# Check results
if [[ $TIME_ISSUES -gt 2 ]]; then
    echo "CRITICAL: Multiple time synchronization issues found ($TIME_ISSUES)" >&2
    exit $RC_FAILED
elif [[ $TIME_ISSUES -gt 0 ]]; then
    echo "WARNING: Time synchronization issues found ($TIME_ISSUES)" >&2
    exit $RC_FAILED
else
    echo "Time synchronization appears to be working properly" >&2
    exit $RC_OKAY
fi
