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

# long_name: Check user accounts security
# description: Check user accounts for security issues
# priority: 810

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

SECURITY_ISSUES=0

if [[ "x$RISU_LIVE" == "x1" ]]; then
    PASSWD_FILE="/etc/passwd"
    SHADOW_FILE="/etc/shadow"
else
    PASSWD_FILE="${RISU_ROOT}/etc/passwd"
    SHADOW_FILE="${RISU_ROOT}/etc/shadow"
fi

if [[ -f $PASSWD_FILE ]]; then
    # Check for accounts with UID 0 (root equivalent)
    ROOT_ACCOUNTS=$(awk -F: '$3 == 0' "$PASSWD_FILE" | grep -v "^root:" | wc -l)
    if [[ $ROOT_ACCOUNTS -gt 0 ]]; then
        echo "CRITICAL: Found $ROOT_ACCOUNTS non-root accounts with UID 0:" >&2
        awk -F: '$3 == 0' "$PASSWD_FILE" | grep -v "^root:" | awk -F: '{print $1}' >&2
        SECURITY_ISSUES=$((SECURITY_ISSUES + ROOT_ACCOUNTS * 3))
    fi

    # Check for accounts with empty passwords
    if [[ -f $SHADOW_FILE ]]; then
        EMPTY_PASSWORDS=$(awk -F: '$2 == "" || $2 == "*" || $2 == "!!"' "$SHADOW_FILE" | wc -l)
        if [[ $EMPTY_PASSWORDS -gt 5 ]]; then
            echo "WARNING: Found $EMPTY_PASSWORDS accounts with empty/locked passwords" >&2
            SECURITY_ISSUES=$((SECURITY_ISSUES + 1))
        fi
    fi

    # Check for accounts with no home directory
    NO_HOME_ACCOUNTS=$(awk -F: '$6 == "" || $6 == "/"' "$PASSWD_FILE" | grep -v "^root:" | wc -l)
    if [[ $NO_HOME_ACCOUNTS -gt 10 ]]; then
        echo "INFO: Found $NO_HOME_ACCOUNTS accounts with no/root home directory" >&2
    fi

    # Check for accounts with interactive shells
    INTERACTIVE_SHELLS=$(awk -F: '$7 ~ /bash|sh|zsh|fish|csh|tcsh/' "$PASSWD_FILE" | wc -l)
    if [[ $INTERACTIVE_SHELLS -gt 20 ]]; then
        echo "WARNING: High number of accounts with interactive shells: $INTERACTIVE_SHELLS" >&2
        SECURITY_ISSUES=$((SECURITY_ISSUES + 1))
    fi

    # Check for duplicate UIDs
    DUPLICATE_UIDS=$(awk -F: '{print $3}' "$PASSWD_FILE" | sort | uniq -d | wc -l)
    if [[ $DUPLICATE_UIDS -gt 0 ]]; then
        echo "WARNING: Found $DUPLICATE_UIDS duplicate UIDs:" >&2
        awk -F: '{print $3}' "$PASSWD_FILE" | sort | uniq -d >&2
        SECURITY_ISSUES=$((SECURITY_ISSUES + DUPLICATE_UIDS))
    fi

    # Check for accounts with suspicious names
    SUSPICIOUS_ACCOUNTS=$(awk -F: '$1 ~ /^(admin|test|guest|temp|demo|user)/' "$PASSWD_FILE" | wc -l)
    if [[ $SUSPICIOUS_ACCOUNTS -gt 0 ]]; then
        echo "WARNING: Found $SUSPICIOUS_ACCOUNTS accounts with suspicious names:" >&2
        awk -F: '$1 ~ /^(admin|test|guest|temp|demo|user)/' "$PASSWD_FILE" | awk -F: '{print $1}' >&2
        SECURITY_ISSUES=$((SECURITY_ISSUES + SUSPICIOUS_ACCOUNTS))
    fi
else
    echo "passwd file not found" >&2
    exit $RC_SKIPPED
fi

# Check results
if [[ $SECURITY_ISSUES -gt 5 ]]; then
    echo "CRITICAL: Multiple user account security issues found ($SECURITY_ISSUES)" >&2
    exit $RC_FAILED
elif [[ $SECURITY_ISSUES -gt 2 ]]; then
    echo "WARNING: User account security issues found ($SECURITY_ISSUES)" >&2
    exit $RC_FAILED
elif [[ $SECURITY_ISSUES -gt 0 ]]; then
    echo "INFO: Minor user account security issues found ($SECURITY_ISSUES)" >&2
    exit $RC_OKAY
else
    echo "User accounts appear to be secure" >&2
    exit $RC_OKAY
fi
