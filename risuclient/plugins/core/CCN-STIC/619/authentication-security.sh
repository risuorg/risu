#!/bin/bash
# Copyright (C) 2024 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>
#
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

# long_name: Validate authentication security configuration
# description: Validate authentication and user security settings for CCN-STIC-619
# priority: 130
# bugzilla: https://www.ccn-cert.cni.es/pdf/guias/series-ccn-stic/guias-de-acceso-publico-ccn-stic/3674-ccn-stic-619-implementacion-de-seguridad-sobre-centos7/file.html

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

flag=0

echo "Checking authentication security configuration..." >&2

# Check PAM configuration
PAM_DIR="${RISU_ROOT}/etc/pam.d"
PAM_SYSTEM_AUTH="${PAM_DIR}/system-auth"
PAM_PASSWORD_AUTH="${PAM_DIR}/password-auth"

# Check if PAM files exist
if [[ -f ${PAM_SYSTEM_AUTH} ]]; then
    # Check for pam_faillock (account lockout)
    if ! grep -q "pam_faillock.so" "${PAM_SYSTEM_AUTH}"; then
        echo "PAM faillock not configured in system-auth" >&2
        flag=1
    fi

    # Check for pam_pwquality (password quality)
    if ! grep -q "pam_pwquality.so" "${PAM_SYSTEM_AUTH}"; then
        echo "PAM password quality not configured in system-auth" >&2
        flag=1
    fi

    # Check for pam_pwhistory (password history)
    if ! grep -q "pam_pwhistory.so" "${PAM_SYSTEM_AUTH}"; then
        echo "PAM password history not configured in system-auth" >&2
        flag=1
    fi
fi

# Check pwquality configuration
PWQUALITY_CONF="${RISU_ROOT}/etc/security/pwquality.conf"
if [[ -f ${PWQUALITY_CONF} ]]; then
    # Check minimum password length
    minlen=$(grep "^minlen" "${PWQUALITY_CONF}" | cut -d'=' -f2 | tr -d ' ')
    if [[ -z ${minlen} || ${minlen} -lt 8 ]]; then
        echo "Password minimum length not set or too low (should be >= 8)" >&2
        flag=1
    fi

    # Check password complexity requirements
    if ! grep -q "^minclass" "${PWQUALITY_CONF}"; then
        echo "Password complexity (minclass) not configured" >&2
        flag=1
    fi

    # Check maximum consecutive characters
    if ! grep -q "^maxrepeat" "${PWQUALITY_CONF}"; then
        echo "Maximum consecutive characters (maxrepeat) not configured" >&2
        flag=1
    fi

    # Check maximum class repeats
    if ! grep -q "^maxclassrepeat" "${PWQUALITY_CONF}"; then
        echo "Maximum class repeats (maxclassrepeat) not configured" >&2
        flag=1
    fi
else
    echo "Password quality configuration file not found" >&2
    flag=1
fi

# Check faillock configuration
FAILLOCK_CONF="${RISU_ROOT}/etc/security/faillock.conf"
if [[ -f ${FAILLOCK_CONF} ]]; then
    # Check deny attempts
    deny=$(grep "^deny" "${FAILLOCK_CONF}" | cut -d'=' -f2 | tr -d ' ')
    if [[ -z ${deny} || ${deny} -gt 5 ]]; then
        echo "Account lockout attempts not set or too high (should be <= 5)" >&2
        flag=1
    fi

    # Check unlock time
    unlock_time=$(grep "^unlock_time" "${FAILLOCK_CONF}" | cut -d'=' -f2 | tr -d ' ')
    if [[ -z ${unlock_time} || ${unlock_time} -lt 900 ]]; then
        echo "Account unlock time not set or too low (should be >= 900 seconds)" >&2
        flag=1
    fi
fi

# Check user account security
PASSWD_FILE="${RISU_ROOT}/etc/passwd"
SHADOW_FILE="${RISU_ROOT}/etc/shadow"

if [[ -f ${PASSWD_FILE} ]]; then
    # Check for users with UID 0 (besides root)
    root_users=$(awk -F: '$3 == 0 && $1 != "root" {print $1}' "${PASSWD_FILE}")
    if [[ -n ${root_users} ]]; then
        echo "Users with UID 0 (besides root): ${root_users}" >&2
        flag=1
    fi

    # Check for users with empty passwords
    if [[ -f ${SHADOW_FILE} ]]; then
        empty_pass_users=$(awk -F: '$2 == "" {print $1}' "${SHADOW_FILE}")
        if [[ -n ${empty_pass_users} ]]; then
            echo "Users with empty passwords: ${empty_pass_users}" >&2
            flag=1
        fi

        # Check for users with weak password hashes
        weak_hash_users=$(awk -F: '$2 ~ /^\$1\$/ {print $1}' "${SHADOW_FILE}")
        if [[ -n ${weak_hash_users} ]]; then
            echo "Users with weak MD5 password hashes: ${weak_hash_users}" >&2
            flag=1
        fi
    fi

    # Check for system accounts with login shells
    system_accounts_with_shell=$(awk -F: '$3 < 1000 && $3 != 0 && $7 != "/sbin/nologin" && $7 != "/bin/false" && $7 != "/usr/sbin/nologin" {print $1}' "${PASSWD_FILE}")
    if [[ -n ${system_accounts_with_shell} ]]; then
        echo "System accounts with login shells: ${system_accounts_with_shell}" >&2
        flag=1
    fi
fi

# Check sudo configuration
SUDOERS_FILE="${RISU_ROOT}/etc/sudoers"
SUDOERS_D_DIR="${RISU_ROOT}/etc/sudoers.d"

if [[ -f ${SUDOERS_FILE} ]]; then
    # Check for NOPASSWD rules
    if grep -q "NOPASSWD" "${SUDOERS_FILE}"; then
        echo "Sudo NOPASSWD rules found in sudoers file" >&2
        flag=1
    fi

    # Check for overly permissive rules
    if grep -q "ALL.*ALL.*ALL" "${SUDOERS_FILE}"; then
        echo "Overly permissive sudo rules found" >&2
        flag=1
    fi
fi

if [[ -d ${SUDOERS_D_DIR} ]]; then
    for sudoers_file in "${SUDOERS_D_DIR}"/*; do
        if [[ -f ${sudoers_file} ]]; then
            if grep -q "NOPASSWD" "${sudoers_file}"; then
                echo "Sudo NOPASSWD rules found in $(basename ${sudoers_file})" >&2
                flag=1
            fi

            if grep -q "ALL.*ALL.*ALL" "${sudoers_file}"; then
                echo "Overly permissive sudo rules found in $(basename ${sudoers_file})" >&2
                flag=1
            fi
        fi
    done
fi

# Check login.defs (extending existing check)
LOGIN_DEFS="${RISU_ROOT}/etc/login.defs"
if [[ -f ${LOGIN_DEFS} ]]; then
    # Check password aging
    pass_max_days=$(grep "^PASS_MAX_DAYS" "${LOGIN_DEFS}" | awk '{print $2}')
    if [[ -z ${pass_max_days} || ${pass_max_days} -gt 90 ]]; then
        echo "Password maximum age not set or too high (should be <= 90 days)" >&2
        flag=1
    fi

    # Check password minimum age
    pass_min_days=$(grep "^PASS_MIN_DAYS" "${LOGIN_DEFS}" | awk '{print $2}')
    if [[ -z ${pass_min_days} || ${pass_min_days} -lt 1 ]]; then
        echo "Password minimum age not set or too low (should be >= 1 day)" >&2
        flag=1
    fi

    # Check warning age
    pass_warn_age=$(grep "^PASS_WARN_AGE" "${LOGIN_DEFS}" | awk '{print $2}')
    if [[ -z ${pass_warn_age} || ${pass_warn_age} -lt 7 ]]; then
        echo "Password warning age not set or too low (should be >= 7 days)" >&2
        flag=1
    fi

    # Check UMASK
    umask_value=$(grep "^UMASK" "${LOGIN_DEFS}" | awk '{print $2}')
    if [[ -z ${umask_value} || ${umask_value} != "077" ]]; then
        echo "UMASK not set to secure value (should be 077)" >&2
        flag=1
    fi
fi

# Check for .rhosts and .netrc files
RHOSTS_FILES=$(find "${RISU_ROOT}/home" -name ".rhosts" -o -name ".netrc" 2>/dev/null)
if [[ -n ${RHOSTS_FILES} ]]; then
    echo "Found insecure .rhosts or .netrc files: ${RHOSTS_FILES}" >&2
    flag=1
fi

# Check SSH key permissions
SSH_KEYS=$(find "${RISU_ROOT}/home" -name "authorized_keys" -o -name "id_rsa" -o -name "id_dsa" -o -name "id_ecdsa" -o -name "id_ed25519" 2>/dev/null)
for key_file in ${SSH_KEYS}; do
    if [[ -f ${key_file} ]]; then
        # Check permissions (should be 600 for private keys, 644 for authorized_keys)
        if [[ ${key_file} == *"authorized_keys" ]]; then
            echo "Found SSH authorized_keys file: ${key_file}" >&2
        else
            echo "Found SSH private key file: ${key_file}" >&2
        fi
    fi
done

if [[ $flag -eq 1 ]]; then
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
