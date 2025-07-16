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

# long_name: Check SSH configuration security
# description: Check SSH daemon configuration for security issues
# priority: 810

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

SECURITY_ISSUES=0

if [[ "x$RISU_LIVE" == "x1" ]]; then
    SSHD_CONFIG="/etc/ssh/sshd_config"
else
    SSHD_CONFIG="${RISU_ROOT}/etc/ssh/sshd_config"
fi

if [[ -f $SSHD_CONFIG ]]; then
    # Check for root login
    if grep -q "^PermitRootLogin yes" "$SSHD_CONFIG"; then
        echo "WARNING: Root login is enabled in SSH configuration" >&2
        SECURITY_ISSUES=$((SECURITY_ISSUES + 1))
    fi

    # Check for password authentication
    if grep -q "^PasswordAuthentication yes" "$SSHD_CONFIG"; then
        echo "WARNING: Password authentication is enabled in SSH" >&2
        SECURITY_ISSUES=$((SECURITY_ISSUES + 1))
    fi

    # Check for empty passwords
    if grep -q "^PermitEmptyPasswords yes" "$SSHD_CONFIG"; then
        echo "CRITICAL: Empty passwords are allowed in SSH" >&2
        SECURITY_ISSUES=$((SECURITY_ISSUES + 2))
    fi

    # Check for X11 forwarding
    if grep -q "^X11Forwarding yes" "$SSHD_CONFIG"; then
        echo "INFO: X11 forwarding is enabled (potential security risk)" >&2
    fi

    # Check for protocol version
    if grep -q "^Protocol 1" "$SSHD_CONFIG"; then
        echo "CRITICAL: SSH Protocol 1 is enabled (deprecated and insecure)" >&2
        SECURITY_ISSUES=$((SECURITY_ISSUES + 3))
    fi

    # Check for weak ciphers
    if grep -q "^Ciphers.*des" "$SSHD_CONFIG"; then
        echo "WARNING: Weak DES ciphers are enabled in SSH" >&2
        SECURITY_ISSUES=$((SECURITY_ISSUES + 1))
    fi

    # Check max auth tries
    MAX_AUTH_TRIES=$(grep "^MaxAuthTries" "$SSHD_CONFIG" | awk '{print $2}' || echo "6")
    if [[ $MAX_AUTH_TRIES -gt 3 ]]; then
        echo "WARNING: MaxAuthTries is set too high ($MAX_AUTH_TRIES)" >&2
        SECURITY_ISSUES=$((SECURITY_ISSUES + 1))
    fi

    # Check for host-based authentication
    if grep -q "^HostbasedAuthentication yes" "$SSHD_CONFIG"; then
        echo "WARNING: Host-based authentication is enabled" >&2
        SECURITY_ISSUES=$((SECURITY_ISSUES + 1))
    fi
else
    echo "SSH configuration file not found" >&2
    exit $RC_SKIPPED
fi

# Check results
if [[ $SECURITY_ISSUES -gt 5 ]]; then
    echo "CRITICAL: Multiple SSH security issues found ($SECURITY_ISSUES)" >&2
    exit $RC_FAILED
elif [[ $SECURITY_ISSUES -gt 2 ]]; then
    echo "WARNING: SSH security issues found ($SECURITY_ISSUES)" >&2
    exit $RC_FAILED
elif [[ $SECURITY_ISSUES -gt 0 ]]; then
    echo "INFO: Minor SSH security issues found ($SECURITY_ISSUES)" >&2
    exit $RC_OKAY
else
    echo "SSH configuration appears to be secure" >&2
    exit $RC_OKAY
fi
