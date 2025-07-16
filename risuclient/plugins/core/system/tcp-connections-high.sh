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

# long_name: Check for high TCP connection count
# description: Check if TCP connection count is above critical thresholds
# priority: 400

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

# Set thresholds
WARNING_THRESHOLD=1000
CRITICAL_THRESHOLD=5000

if [[ "x$RISU_LIVE" == "x1" ]]; then
    # Get current TCP connections
    if [[ -f "/proc/net/tcp" ]]; then
        TCP_CONNECTIONS=$(grep -c "^" /proc/net/tcp)
        # Subtract header line
        TCP_CONNECTIONS=$((TCP_CONNECTIONS - 1))
    else
        echo "/proc/net/tcp not available" >&2
        exit $RC_SKIPPED
    fi
else
    # Check sosreport for TCP connections
    if [[ -f "${RISU_ROOT}/proc/net/tcp" ]]; then
        TCP_CONNECTIONS=$(grep -c "^" "${RISU_ROOT}/proc/net/tcp")
        # Subtract header line
        TCP_CONNECTIONS=$((TCP_CONNECTIONS - 1))
    else
        echo "proc/net/tcp file not found in sosreport" >&2
        exit $RC_SKIPPED
    fi
fi

# Analyze TCP connection states
if [[ "x$RISU_LIVE" == "x1" ]]; then
    if command -v ss >/dev/null 2>&1; then
        ESTABLISHED=$(ss -t state established | grep -c "ESTAB")
        TIME_WAIT=$(ss -t state time-wait | grep -c "TIME-WAIT")
        CLOSE_WAIT=$(ss -t state close-wait | grep -c "CLOSE-WAIT")
    else
        ESTABLISHED=0
        TIME_WAIT=0
        CLOSE_WAIT=0
    fi
else
    # Try to analyze from sosreport
    if [[ -f "${RISU_ROOT}/netstat_-anp" ]]; then
        ESTABLISHED=$(grep -c "ESTABLISHED" "${RISU_ROOT}/netstat_-anp")
        TIME_WAIT=$(grep -c "TIME_WAIT" "${RISU_ROOT}/netstat_-anp")
        CLOSE_WAIT=$(grep -c "CLOSE_WAIT" "${RISU_ROOT}/netstat_-anp")
    else
        ESTABLISHED=0
        TIME_WAIT=0
        CLOSE_WAIT=0
    fi
fi

# Check connection count against thresholds
if [[ $TCP_CONNECTIONS -ge $CRITICAL_THRESHOLD ]]; then
    echo "CRITICAL: TCP connections count is $TCP_CONNECTIONS (threshold: $CRITICAL_THRESHOLD)" >&2
    echo "  ESTABLISHED: $ESTABLISHED, TIME_WAIT: $TIME_WAIT, CLOSE_WAIT: $CLOSE_WAIT" >&2
    exit $RC_FAILED
elif [[ $TCP_CONNECTIONS -ge $WARNING_THRESHOLD ]]; then
    echo "WARNING: TCP connections count is $TCP_CONNECTIONS (threshold: $WARNING_THRESHOLD)" >&2
    echo "  ESTABLISHED: $ESTABLISHED, TIME_WAIT: $TIME_WAIT, CLOSE_WAIT: $CLOSE_WAIT" >&2
    exit $RC_FAILED
else
    echo "TCP connections count is normal: $TCP_CONNECTIONS (ESTABLISHED: $ESTABLISHED, TIME_WAIT: $TIME_WAIT, CLOSE_WAIT: $CLOSE_WAIT)" >&2
    exit $RC_OKAY
fi
