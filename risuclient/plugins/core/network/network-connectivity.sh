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

# long_name: Check network connectivity
# description: Check basic network connectivity and routing
# priority: 870

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

CONNECTIVITY_ISSUES=0

if [[ "x$RISU_LIVE" == "x1" ]]; then
    # Test network connectivity
    if command -v ping >/dev/null 2>&1; then
        # Test ping to common hosts
        TEST_HOSTS=("8.8.8.8" "1.1.1.1")

        for host in "${TEST_HOSTS[@]}"; do
            if ! ping -c 1 -W 3 "$host" >/dev/null 2>&1; then
                echo "WARNING: Cannot ping $host" >&2
                CONNECTIVITY_ISSUES=$((CONNECTIVITY_ISSUES + 1))
            fi
        done
    else
        echo "ping command not available" >&2
        exit $RC_SKIPPED
    fi

    # Check default route
    if command -v ip >/dev/null 2>&1; then
        if ! ip route show default >/dev/null 2>&1; then
            echo "WARNING: No default route configured" >&2
            CONNECTIVITY_ISSUES=$((CONNECTIVITY_ISSUES + 1))
        fi
    fi

    # Check network interfaces
    if [[ -f "/proc/net/dev" ]]; then
        ACTIVE_INTERFACES=$(grep -c ":" /proc/net/dev)
        if [[ $ACTIVE_INTERFACES -lt 2 ]]; then
            echo "WARNING: Very few network interfaces active ($ACTIVE_INTERFACES)" >&2
            CONNECTIVITY_ISSUES=$((CONNECTIVITY_ISSUES + 1))
        fi
    fi
else
    # Check sosreport for network configuration
    if [[ -f "${RISU_ROOT}/ip_route_show" ]]; then
        if ! grep -q "default" "${RISU_ROOT}/ip_route_show"; then
            echo "WARNING: No default route was configured" >&2
            CONNECTIVITY_ISSUES=$((CONNECTIVITY_ISSUES + 1))
        fi
    else
        echo "WARNING: No routing information found in sosreport" >&2
        CONNECTIVITY_ISSUES=$((CONNECTIVITY_ISSUES + 1))
    fi

    # Check network interfaces
    if [[ -f "${RISU_ROOT}/proc/net/dev" ]]; then
        ACTIVE_INTERFACES=$(grep -c ":" "${RISU_ROOT}/proc/net/dev")
        if [[ $ACTIVE_INTERFACES -lt 2 ]]; then
            echo "WARNING: Very few network interfaces were active ($ACTIVE_INTERFACES)" >&2
            CONNECTIVITY_ISSUES=$((CONNECTIVITY_ISSUES + 1))
        fi
    fi
fi

# Check results
if [[ $CONNECTIVITY_ISSUES -gt 2 ]]; then
    echo "CRITICAL: Multiple network connectivity issues ($CONNECTIVITY_ISSUES)" >&2
    exit $RC_FAILED
elif [[ $CONNECTIVITY_ISSUES -gt 0 ]]; then
    echo "WARNING: Network connectivity issues found ($CONNECTIVITY_ISSUES)" >&2
    exit $RC_FAILED
else
    echo "Network connectivity appears to be working properly" >&2
    exit $RC_OKAY
fi
