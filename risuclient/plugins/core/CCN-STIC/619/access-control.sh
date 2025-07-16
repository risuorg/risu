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

# long_name: Validate access control configuration
# description: Validate sudo, SELinux and access control settings for CCN-STIC-619
# priority: 130
# bugzilla: https://www.ccn-cert.cni.es/pdf/guias/series-ccn-stic/guias-de-acceso-publico-ccn-stic/3674-ccn-stic-619-implementacion-de-seguridad-sobre-centos7/file.html

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

flag=0

echo "Checking access control configuration..." >&2

# Check sudo configuration
SUDOERS_FILE="${RISU_ROOT}/etc/sudoers"
SUDOERS_D_DIR="${RISU_ROOT}/etc/sudoers.d"

if [[ -f ${SUDOERS_FILE} ]]; then
    echo "Checking sudo configuration..." >&2

    # Check for NOPASSWD rules
    if grep -q "NOPASSWD" "${SUDOERS_FILE}"; then
        echo "Sudo NOPASSWD rules found in sudoers file" >&2
        flag=1
    fi

    # Check for overly permissive rules
    if grep -q "ALL.*ALL.*ALL" "${SUDOERS_FILE}"; then
        echo "Overly permissive sudo rules found (ALL ALL ALL)" >&2
        flag=1
    fi

    # Check for root privileges without password
    if grep -q "^[^#]*ALL.*NOPASSWD.*ALL" "${SUDOERS_FILE}"; then
        echo "Sudo rules allow root privileges without password" >&2
        flag=1
    fi

    # Check for secure path
    if ! grep -q "secure_path" "${SUDOERS_FILE}"; then
        echo "Sudo secure_path not configured" >&2
        flag=1
    fi

    # Check for log file configuration
    if ! grep -q "logfile" "${SUDOERS_FILE}"; then
        echo "Sudo logging not configured" >&2
        flag=1
    fi

    # Check for timeout settings
    if ! grep -q "timestamp_timeout" "${SUDOERS_FILE}"; then
        echo "Sudo timestamp timeout not configured" >&2
        flag=1
    fi

    # Check for environment variable restrictions
    if ! grep -q "env_reset" "${SUDOERS_FILE}"; then
        echo "Sudo environment reset not configured" >&2
        flag=1
    fi
else
    echo "Sudoers file not found" >&2
    flag=1
fi

# Check sudoers.d directory
if [[ -d ${SUDOERS_D_DIR} ]]; then
    for sudoers_file in "${SUDOERS_D_DIR}"/*; do
        if [[ -f ${sudoers_file} ]]; then
            filename=$(basename "${sudoers_file}")

            # Check for NOPASSWD rules
            if grep -q "NOPASSWD" "${sudoers_file}"; then
                echo "Sudo NOPASSWD rules found in ${filename}" >&2
                flag=1
            fi

            # Check for overly permissive rules
            if grep -q "ALL.*ALL.*ALL" "${sudoers_file}"; then
                echo "Overly permissive sudo rules found in ${filename}" >&2
                flag=1
            fi

            # Check for dangerous wildcards
            if grep -q "\*" "${sudoers_file}"; then
                echo "Sudo wildcards found in ${filename}" >&2
                flag=1
            fi
        fi
    done
fi

# Check SELinux configuration
SELINUX_CONFIG="${RISU_ROOT}/etc/selinux/config"
if [[ -f ${SELINUX_CONFIG} ]]; then
    echo "Checking SELinux configuration..." >&2

    # Check SELinux state
    selinux_state=$(grep "^SELINUX=" "${SELINUX_CONFIG}" | cut -d'=' -f2)
    if [[ ${selinux_state} != "enforcing" ]]; then
        echo "SELinux not in enforcing mode: ${selinux_state}" >&2
        flag=1
    fi

    # Check SELinux policy type
    selinux_type=$(grep "^SELINUXTYPE=" "${SELINUX_CONFIG}" | cut -d'=' -f2)
    if [[ ${selinux_type} != "targeted" && ${selinux_type} != "strict" ]]; then
        echo "SELinux policy type not secure: ${selinux_type}" >&2
        flag=1
    fi
else
    echo "SELinux configuration file not found" >&2
    flag=1
fi

# Check SELinux status from live system or sosreport
SELINUX_STATUS_FILE="${RISU_ROOT}/sos_commands/selinux/sestatus_-b"
if [[ -f ${SELINUX_STATUS_FILE} ]]; then
    if grep -q "SELinux status:.*disabled" "${SELINUX_STATUS_FILE}"; then
        echo "SELinux is disabled" >&2
        flag=1
    fi

    if grep -q "Current mode:.*permissive" "${SELINUX_STATUS_FILE}"; then
        echo "SELinux is in permissive mode" >&2
        flag=1
    fi
fi

# Check for SELinux denials
SELINUX_AUDIT_LOG="${RISU_ROOT}/var/log/audit/audit.log"
if [[ -f ${SELINUX_AUDIT_LOG} ]]; then
    selinux_denials=$(grep -c "AVC.*denied" "${SELINUX_AUDIT_LOG}" 2>/dev/null || echo "0")
    if [[ ${selinux_denials} -gt 0 ]]; then
        echo "SELinux denials found: ${selinux_denials}" >&2
        # This is informational, not necessarily a failure
    fi
fi

# Check for SELinux boolean settings
SELINUX_BOOLEANS_FILE="${RISU_ROOT}/sos_commands/selinux/getsebool_-a"
if [[ -f ${SELINUX_BOOLEANS_FILE} ]]; then
    # Check for dangerous booleans that should be off
    DANGEROUS_BOOLEANS=(
        "httpd_can_network_connect"
        "httpd_execmem"
        "httpd_unified"
        "allow_execheap"
        "allow_execmem"
        "allow_execstack"
        "secure_mode_insmod"
        "secure_mode_policyload"
    )

    for boolean in "${DANGEROUS_BOOLEANS[@]}"; do
        if grep -q "^${boolean}.*on" "${SELINUX_BOOLEANS_FILE}"; then
            echo "Dangerous SELinux boolean enabled: ${boolean}" >&2
            flag=1
        fi
    done
fi

# Check file contexts
SELINUX_CONTEXTS_FILE="${RISU_ROOT}/sos_commands/selinux/ls_-lZ_/etc"
if [[ -f ${SELINUX_CONTEXTS_FILE} ]]; then
    # Check for files with wrong contexts
    if grep -q "unlabeled_t" "${SELINUX_CONTEXTS_FILE}"; then
        echo "Files with unlabeled SELinux contexts found" >&2
        flag=1
    fi
fi

# Check polkit configuration
POLKIT_DIR="${RISU_ROOT}/etc/polkit-1"
if [[ -d ${POLKIT_DIR} ]]; then
    echo "Checking polkit configuration..." >&2

    # Check for custom polkit rules
    POLKIT_RULES_DIR="${POLKIT_DIR}/rules.d"
    if [[ -d ${POLKIT_RULES_DIR} ]]; then
        for rule_file in "${POLKIT_RULES_DIR}"/*.rules; do
            if [[ -f ${rule_file} ]]; then
                filename=$(basename "${rule_file}")

                # Check for overly permissive rules
                if grep -q "return polkit.Result.YES" "${rule_file}"; then
                    echo "Overly permissive polkit rule found in ${filename}" >&2
                    flag=1
                fi
            fi
        done
    fi
fi

# Check for wheel group usage
WHEEL_GROUP_FILE="${RISU_ROOT}/etc/group"
if [[ -f ${WHEEL_GROUP_FILE} ]]; then
    wheel_users=$(grep "^wheel:" "${WHEEL_GROUP_FILE}" | cut -d':' -f4)
    if [[ -n ${wheel_users} ]]; then
        echo "Users in wheel group: ${wheel_users}" >&2

        # Check if wheel group is properly configured in sudoers
        if [[ -f ${SUDOERS_FILE} ]]; then
            if ! grep -q "^%wheel" "${SUDOERS_FILE}"; then
                echo "Wheel group not configured in sudoers" >&2
                flag=1
            fi
        fi
    fi
fi

# Check for administrator accounts
ADMIN_ACCOUNTS=(
    "admin"
    "administrator"
    "root"
    "toor"
    "operator"
    "mysql"
    "postgres"
    "apache"
    "www-data"
    "nobody"
)

PASSWD_FILE="${RISU_ROOT}/etc/passwd"
if [[ -f ${PASSWD_FILE} ]]; then
    echo "Checking for administrative accounts..." >&2

    for account in "${ADMIN_ACCOUNTS[@]}"; do
        if grep -q "^${account}:" "${PASSWD_FILE}"; then
            # Check if account has appropriate shell
            shell=$(grep "^${account}:" "${PASSWD_FILE}" | cut -d':' -f7)
            uid=$(grep "^${account}:" "${PASSWD_FILE}" | cut -d':' -f3)

            if [[ ${account} == "root" ]]; then
                if [[ ${shell} == "/sbin/nologin" || ${shell} == "/bin/false" ]]; then
                    echo "Root account has no login shell" >&2
                    flag=1
                fi
            else
                if [[ ${shell} != "/sbin/nologin" && ${shell} != "/bin/false" && ${shell} != "/usr/sbin/nologin" ]]; then
                    echo "Service account ${account} has login shell: ${shell}" >&2
                    flag=1
                fi
            fi
        fi
    done
fi

# Check for default passwords
SHADOW_FILE="${RISU_ROOT}/etc/shadow"
if [[ -f ${SHADOW_FILE} ]]; then
    echo "Checking for default passwords..." >&2

    # Check for empty passwords
    empty_passwords=$(awk -F':' '$2 == "" {print $1}' "${SHADOW_FILE}")
    if [[ -n ${empty_passwords} ]]; then
        echo "Accounts with empty passwords: ${empty_passwords}" >&2
        flag=1
    fi

    # Check for locked accounts
    locked_accounts=$(awk -F':' '$2 ~ /^!/ {print $1}' "${SHADOW_FILE}")
    if [[ -n ${locked_accounts} ]]; then
        echo "Locked accounts found: ${locked_accounts}" >&2
        # This is informational, not necessarily a failure
    fi
fi

# Check for access control lists (ACLs)
ACL_COMMANDS_FILE="${RISU_ROOT}/sos_commands/filesys/getfacl_-a_-R_-p_-s_-k_-n_-t_/etc"
if [[ -f ${ACL_COMMANDS_FILE} ]]; then
    echo "Checking file ACLs..." >&2

    # Check for overly permissive ACLs
    if grep -q "other::rwx" "${ACL_COMMANDS_FILE}"; then
        echo "Overly permissive ACLs found (other::rwx)" >&2
        flag=1
    fi
fi

# Check for capabilities
CAPABILITIES_FILE="${RISU_ROOT}/sos_commands/filesys/getcap_-r_/"
if [[ -f ${CAPABILITIES_FILE} ]]; then
    echo "Checking file capabilities..." >&2

    # Check for dangerous capabilities
    DANGEROUS_CAPABILITIES=(
        "cap_sys_admin"
        "cap_sys_ptrace"
        "cap_sys_module"
        "cap_sys_rawio"
        "cap_dac_override"
        "cap_setuid"
        "cap_setgid"
    )

    for cap in "${DANGEROUS_CAPABILITIES[@]}"; do
        if grep -q "${cap}" "${CAPABILITIES_FILE}"; then
            echo "Dangerous capability found: ${cap}" >&2
            flag=1
        fi
    done
fi

# Check for umask settings
PROFILE_FILES=(
    "/etc/profile"
    "/etc/bashrc"
    "/etc/csh.cshrc"
    "/etc/zsh/zprofile"
)

for profile_file in "${PROFILE_FILES[@]}"; do
    full_profile_file="${RISU_ROOT}${profile_file}"
    if [[ -f ${full_profile_file} ]]; then
        # Check for secure umask
        if grep -q "umask" "${full_profile_file}"; then
            umask_value=$(grep "umask" "${full_profile_file}" | tail -1 | awk '{print $2}')
            if [[ ${umask_value} != "077" && ${umask_value} != "027" ]]; then
                echo "Insecure umask in ${profile_file}: ${umask_value}" >&2
                flag=1
            fi
        else
            echo "No umask setting found in ${profile_file}" >&2
            flag=1
        fi
    fi
done

if [[ $flag -eq 1 ]]; then
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
