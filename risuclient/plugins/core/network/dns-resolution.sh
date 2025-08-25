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

# long_name: Check DNS resolution functionality
# description: Check if DNS resolution is working properly
# priority: 870

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

DNS_ISSUES=0

if [[ "x$RISU_LIVE" == "x1" ]]; then
    # Test DNS resolution
    if command -v nslookup >/dev/null 2>&1; then
        # Test common DNS lookups
        TEST_DOMAINS=("google.com" "redhat.com" "github.com")

        for domain in "${TEST_DOMAINS[@]}"; do
            if ! nslookup "$domain" >/dev/null 2>&1; then
                echo "WARNING: DNS resolution failed for $domain" >&2
                DNS_ISSUES=$((DNS_ISSUES + 1))
            fi
        done
    else
        echo "nslookup command not available" >&2
        exit $RC_SKIPPED
    fi

    # Check DNS configuration
    if [[ -f "/etc/resolv.conf" ]]; then
        NAMESERVERS=$(grep "^nameserver" /etc/resolv.conf | wc -l)
        if [[ $NAMESERVERS -eq 0 ]]; then
            echo "WARNING: No nameservers configured in /etc/resolv.conf" >&2
            DNS_ISSUES=$((DNS_ISSUES + 1))
        fi
    else
        echo "WARNING: /etc/resolv.conf not found" >&2
        DNS_ISSUES=$((DNS_ISSUES + 1))
    fi
else
    # Check sosreport for DNS configuration
    if [[ -f "${RISU_ROOT}/etc/resolv.conf" ]]; then
        NAMESERVERS=$(grep "^nameserver" "${RISU_ROOT}/etc/resolv.conf" | wc -l)
        if [[ $NAMESERVERS -eq 0 ]]; then
            echo "WARNING: No nameservers were configured in /etc/resolv.conf" >&2
            DNS_ISSUES=$((DNS_ISSUES + 1))
        fi
    else
        echo "WARNING: /etc/resolv.conf not found in sosreport" >&2
        DNS_ISSUES=$((DNS_ISSUES + 1))
    fi
fi

# Check results
if [[ $DNS_ISSUES -gt 2 ]]; then
    echo "CRITICAL: Multiple DNS issues found ($DNS_ISSUES)" >&2
    exit $RC_FAILED
elif [[ $DNS_ISSUES -gt 0 ]]; then
    echo "WARNING: DNS issues found ($DNS_ISSUES)" >&2
    exit $RC_FAILED
else
    echo "DNS resolution appears to be working properly" >&2
    exit $RC_OKAY
fi
