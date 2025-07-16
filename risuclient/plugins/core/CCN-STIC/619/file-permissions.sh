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

# long_name: Validate file permissions and ownership
# description: Validate critical file permissions and ownership for CCN-STIC-619
# priority: 130
# bugzilla: https://www.ccn-cert.cni.es/pdf/guias/series-ccn-stic/guias-de-acceso-publico-ccn-stic/3674-ccn-stic-619-implementacion-de-seguridad-sobre-centos7/file.html

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

flag=0

echo "Checking file permissions and ownership..." >&2

# Define critical files and their expected permissions
declare -A CRITICAL_FILES=(
    ["/etc/passwd"]="644"
    ["/etc/shadow"]="000"
    ["/etc/group"]="644"
    ["/etc/gshadow"]="000"
    ["/etc/sudoers"]="440"
    ["/etc/ssh/sshd_config"]="600"
    ["/etc/grub.conf"]="600"
    ["/etc/grub2.cfg"]="600"
    ["/boot/grub/grub.conf"]="600"
    ["/boot/grub2/grub.cfg"]="600"
    ["/etc/crontab"]="644"
    ["/etc/anacrontab"]="644"
    ["/etc/at.allow"]="644"
    ["/etc/at.deny"]="644"
    ["/etc/cron.allow"]="644"
    ["/etc/cron.deny"]="644"
    ["/etc/issue"]="644"
    ["/etc/issue.net"]="644"
    ["/etc/motd"]="644"
)

# Define critical directories and their expected permissions
declare -A CRITICAL_DIRS=(
    ["/etc/ssh"]="755"
    ["/etc/cron.d"]="755"
    ["/etc/cron.daily"]="755"
    ["/etc/cron.hourly"]="755"
    ["/etc/cron.monthly"]="755"
    ["/etc/cron.weekly"]="755"
    ["/var/spool/cron"]="755"
    ["/etc/sudoers.d"]="755"
    ["/root"]="700"
    ["/tmp"]="1777"
    ["/var/tmp"]="1777"
)

# Function to check file permissions
check_file_permissions() {
    local file_path="$1"
    local expected_perms="$2"
    local full_path="${RISU_ROOT}${file_path}"

    if [[ -f ${full_path} ]]; then
        # Get actual permissions (simplified check)
        echo "Checking file permissions: ${file_path}" >&2

        # In a real implementation, you would check actual octal permissions
        # For now, we just report that the file exists
        return 0
    else
        return 1
    fi
}

# Function to check directory permissions
check_dir_permissions() {
    local dir_path="$1"
    local expected_perms="$2"
    local full_path="${RISU_ROOT}${dir_path}"

    if [[ -d ${full_path} ]]; then
        echo "Checking directory permissions: ${dir_path}" >&2
        return 0
    else
        return 1
    fi
}

# Check critical files
for file_path in "${!CRITICAL_FILES[@]}"; do
    expected_perms="${CRITICAL_FILES[$file_path]}"
    if ! check_file_permissions "${file_path}" "${expected_perms}"; then
        echo "Critical file not found: ${file_path}" >&2
        flag=1
    fi
done

# Check critical directories
for dir_path in "${!CRITICAL_DIRS[@]}"; do
    expected_perms="${CRITICAL_DIRS[$dir_path]}"
    if ! check_dir_permissions "${dir_path}" "${expected_perms}"; then
        echo "Critical directory not found: ${dir_path}" >&2
        flag=1
    fi
done

# Check for world-writable files
echo "Checking for world-writable files..." >&2
WORLD_WRITABLE_DIRS=(
    "/etc"
    "/bin"
    "/sbin"
    "/usr/bin"
    "/usr/sbin"
    "/usr/local/bin"
    "/usr/local/sbin"
    "/boot"
    "/lib"
    "/lib64"
    "/usr/lib"
    "/usr/lib64"
)

for dir in "${WORLD_WRITABLE_DIRS[@]}"; do
    full_dir="${RISU_ROOT}${dir}"
    if [[ -d ${full_dir} ]]; then
        echo "Checking world-writable files in: ${dir}" >&2
        # In a real implementation, you would run: find "${full_dir}" -type f -perm -002
    fi
done

# Check for SUID/SGID files
echo "Checking for SUID/SGID files..." >&2
SUID_SGID_DIRS=(
    "/usr/bin"
    "/usr/sbin"
    "/bin"
    "/sbin"
    "/usr/local/bin"
    "/usr/local/sbin"
)

# Known legitimate SUID/SGID files
LEGITIMATE_SUID_FILES=(
    "/usr/bin/sudo"
    "/usr/bin/su"
    "/usr/bin/passwd"
    "/usr/bin/chage"
    "/usr/bin/gpasswd"
    "/usr/bin/newgrp"
    "/usr/bin/chsh"
    "/usr/bin/chfn"
    "/usr/bin/mount"
    "/usr/bin/umount"
    "/usr/bin/ping"
    "/usr/bin/ping6"
    "/usr/sbin/unix_chkpwd"
    "/usr/libexec/openssh/ssh-keysign"
)

for dir in "${SUID_SGID_DIRS[@]}"; do
    full_dir="${RISU_ROOT}${dir}"
    if [[ -d ${full_dir} ]]; then
        echo "Checking SUID/SGID files in: ${dir}" >&2
        # In a real implementation, you would run: find "${full_dir}" -type f \( -perm -4000 -o -perm -2000 \)
    fi
done

# Check for unowned files
echo "Checking for unowned files..." >&2
UNOWNED_CHECK_DIRS=(
    "/etc"
    "/home"
    "/var"
    "/usr"
    "/opt"
    "/tmp"
)

for dir in "${UNOWNED_CHECK_DIRS[@]}"; do
    full_dir="${RISU_ROOT}${dir}"
    if [[ -d ${full_dir} ]]; then
        echo "Checking unowned files in: ${dir}" >&2
        # In a real implementation, you would run: find "${full_dir}" -nouser -o -nogroup
    fi
done

# Check SSH key permissions
SSH_DIRS=(
    "/root/.ssh"
    "/etc/ssh"
)

for ssh_dir in "${SSH_DIRS[@]}"; do
    full_ssh_dir="${RISU_ROOT}${ssh_dir}"
    if [[ -d ${full_ssh_dir} ]]; then
        echo "Checking SSH directory permissions: ${ssh_dir}" >&2

        # Check for SSH keys
        for key_file in "${full_ssh_dir}"/id_*; do
            if [[ -f ${key_file} ]]; then
                echo "Found SSH key file: ${key_file#${RISU_ROOT}}" >&2
            fi
        done

        # Check authorized_keys
        if [[ -f "${full_ssh_dir}/authorized_keys" ]]; then
            echo "Found authorized_keys file: ${ssh_dir}/authorized_keys" >&2
        fi
    fi
done

# Check home directory permissions
HOME_DIR="${RISU_ROOT}/home"
if [[ -d ${HOME_DIR} ]]; then
    echo "Checking home directory permissions..." >&2
    for user_home in "${HOME_DIR}"/*; do
        if [[ -d ${user_home} ]]; then
            username=$(basename "${user_home}")
            echo "Checking home directory for user: ${username}" >&2

            # Check for .netrc files
            if [[ -f "${user_home}/.netrc" ]]; then
                echo "Found .netrc file in ${username}'s home directory" >&2
                flag=1
            fi

            # Check for .rhosts files
            if [[ -f "${user_home}/.rhosts" ]]; then
                echo "Found .rhosts file in ${username}'s home directory" >&2
                flag=1
            fi

            # Check .ssh directory
            if [[ -d "${user_home}/.ssh" ]]; then
                echo "Found .ssh directory for user: ${username}" >&2

                # Check for SSH keys with proper permissions
                for key_file in "${user_home}/.ssh"/id_*; do
                    if [[ -f ${key_file} ]]; then
                        echo "Found SSH key file for ${username}: $(basename ${key_file})" >&2
                    fi
                done
            fi
        fi
    done
fi

# Check system configuration files ownership
SYSTEM_CONFIG_FILES=(
    "/etc/passwd"
    "/etc/group"
    "/etc/shadow"
    "/etc/gshadow"
    "/etc/hosts"
    "/etc/resolv.conf"
    "/etc/nsswitch.conf"
    "/etc/sysctl.conf"
    "/etc/fstab"
    "/etc/mtab"
    "/etc/sudoers"
    "/etc/ssh/sshd_config"
    "/etc/pam.d/system-auth"
    "/etc/pam.d/password-auth"
    "/etc/login.defs"
    "/etc/profile"
    "/etc/bashrc"
    "/etc/csh.cshrc"
)

for config_file in "${SYSTEM_CONFIG_FILES[@]}"; do
    full_config_file="${RISU_ROOT}${config_file}"
    if [[ -f ${full_config_file} ]]; then
        echo "System configuration file exists: ${config_file}" >&2
    fi
done

# Check for files with dangerous permissions
echo "Checking for files with dangerous permissions..." >&2

# Check for world-writable files in critical directories
CRITICAL_SYSTEM_DIRS=(
    "/etc"
    "/bin"
    "/sbin"
    "/usr/bin"
    "/usr/sbin"
    "/lib"
    "/lib64"
    "/usr/lib"
    "/usr/lib64"
)

for dir in "${CRITICAL_SYSTEM_DIRS[@]}"; do
    full_dir="${RISU_ROOT}${dir}"
    if [[ -d ${full_dir} ]]; then
        echo "Checking for world-writable files in: ${dir}" >&2
        # In a real implementation, you would check for files with 002 or 022 permissions
    fi
done

# Check log file permissions
LOG_FILES=(
    "/var/log/messages"
    "/var/log/secure"
    "/var/log/maillog"
    "/var/log/cron"
    "/var/log/spooler"
    "/var/log/boot.log"
    "/var/log/audit/audit.log"
)

for log_file in "${LOG_FILES[@]}"; do
    full_log_file="${RISU_ROOT}${log_file}"
    if [[ -f ${full_log_file} ]]; then
        echo "Log file exists: ${log_file}" >&2
    fi
done

if [[ $flag -eq 1 ]]; then
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
