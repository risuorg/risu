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

# long_name: Check for network packet drops
# description: Check if network interfaces are dropping packets
# priority: 870

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

# Set thresholds
WARNING_THRESHOLD=1000
CRITICAL_THRESHOLD=10000

ISSUES_FOUND=0

if [[ "x$RISU_LIVE" == "x1" ]]; then
    # Get current network statistics
    if [[ -f "/proc/net/dev" ]]; then
        while IFS= read -r line; do
            # Skip header lines
            [[ $line =~ ^[[:space:]]*Inter- ]] && continue
            [[ $line =~ ^[[:space:]]*face ]] && continue

            INTERFACE=$(echo "$line" | awk -F: '{print $1}' | tr -d ' ')

            # Skip loopback and virtual interfaces
            [[ $INTERFACE =~ ^lo ]] && continue
            [[ $INTERFACE =~ ^docker ]] && continue
            [[ $INTERFACE =~ ^veth ]] && continue
            [[ $INTERFACE =~ ^br- ]] && continue

            # Parse statistics
            STATS=$(echo "$line" | awk -F: '{print $2}')
            RX_DROPPED=$(echo "$STATS" | awk '{print $4}')
            TX_DROPPED=$(echo "$STATS" | awk '{print $12}')

            if [[ $RX_DROPPED =~ ^[0-9]+$ ]]; then
                if [[ $RX_DROPPED -ge $CRITICAL_THRESHOLD ]]; then
                    echo "CRITICAL: Interface $INTERFACE has $RX_DROPPED RX dropped packets (threshold: $CRITICAL_THRESHOLD)" >&2
                    ISSUES_FOUND=1
                elif [[ $RX_DROPPED -ge $WARNING_THRESHOLD ]]; then
                    echo "WARNING: Interface $INTERFACE has $RX_DROPPED RX dropped packets (threshold: $WARNING_THRESHOLD)" >&2
                    ISSUES_FOUND=1
                fi
            fi

            if [[ $TX_DROPPED =~ ^[0-9]+$ ]]; then
                if [[ $TX_DROPPED -ge $CRITICAL_THRESHOLD ]]; then
                    echo "CRITICAL: Interface $INTERFACE has $TX_DROPPED TX dropped packets (threshold: $CRITICAL_THRESHOLD)" >&2
                    ISSUES_FOUND=1
                elif [[ $TX_DROPPED -ge $WARNING_THRESHOLD ]]; then
                    echo "WARNING: Interface $INTERFACE has $TX_DROPPED TX dropped packets (threshold: $WARNING_THRESHOLD)" >&2
                    ISSUES_FOUND=1
                fi
            fi
        done <"/proc/net/dev"
    else
        echo "/proc/net/dev not available" >&2
        exit $RC_SKIPPED
    fi
else
    # Check sosreport for network statistics
    if [[ -f "${RISU_ROOT}/proc/net/dev" ]]; then
        while IFS= read -r line; do
            # Skip header lines
            [[ $line =~ ^[[:space:]]*Inter- ]] && continue
            [[ $line =~ ^[[:space:]]*face ]] && continue

            INTERFACE=$(echo "$line" | awk -F: '{print $1}' | tr -d ' ')

            # Skip loopback and virtual interfaces
            [[ $INTERFACE =~ ^lo ]] && continue
            [[ $INTERFACE =~ ^docker ]] && continue
            [[ $INTERFACE =~ ^veth ]] && continue
            [[ $INTERFACE =~ ^br- ]] && continue

            # Parse statistics
            STATS=$(echo "$line" | awk -F: '{print $2}')
            RX_DROPPED=$(echo "$STATS" | awk '{print $4}')
            TX_DROPPED=$(echo "$STATS" | awk '{print $12}')

            if [[ $RX_DROPPED =~ ^[0-9]+$ ]]; then
                if [[ $RX_DROPPED -ge $CRITICAL_THRESHOLD ]]; then
                    echo "CRITICAL: Interface $INTERFACE had $RX_DROPPED RX dropped packets (threshold: $CRITICAL_THRESHOLD)" >&2
                    ISSUES_FOUND=1
                elif [[ $RX_DROPPED -ge $WARNING_THRESHOLD ]]; then
                    echo "WARNING: Interface $INTERFACE had $RX_DROPPED RX dropped packets (threshold: $WARNING_THRESHOLD)" >&2
                    ISSUES_FOUND=1
                fi
            fi

            if [[ $TX_DROPPED =~ ^[0-9]+$ ]]; then
                if [[ $TX_DROPPED -ge $CRITICAL_THRESHOLD ]]; then
                    echo "CRITICAL: Interface $INTERFACE had $TX_DROPPED TX dropped packets (threshold: $CRITICAL_THRESHOLD)" >&2
                    ISSUES_FOUND=1
                elif [[ $TX_DROPPED -ge $WARNING_THRESHOLD ]]; then
                    echo "WARNING: Interface $INTERFACE had $TX_DROPPED TX dropped packets (threshold: $WARNING_THRESHOLD)" >&2
                    ISSUES_FOUND=1
                fi
            fi
        done <"${RISU_ROOT}/proc/net/dev"
    else
        echo "proc/net/dev file not found in sosreport" >&2
        exit $RC_SKIPPED
    fi
fi

if [[ $ISSUES_FOUND -eq 1 ]]; then
    exit $RC_FAILED
else
    echo "No significant packet drops detected on network interfaces" >&2
    exit $RC_OKAY
fi
