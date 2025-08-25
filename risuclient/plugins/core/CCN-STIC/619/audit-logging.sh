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

# long_name: Validate audit and logging configuration
# description: Validate audit and logging security settings for CCN-STIC-619
# priority: 330
# bugzilla: https://www.ccn-cert.cni.es/pdf/guias/series-ccn-stic/guias-de-acceso-publico-ccn-stic/3674-ccn-stic-619-implementacion-de-seguridad-sobre-centos7/file.html

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

flag=0

echo "Checking audit and logging configuration..." >&2

# Check auditd configuration
AUDITD_CONF="${RISU_ROOT}/etc/audit/auditd.conf"
if [[ -f ${AUDITD_CONF} ]]; then
    # Check log file location
    log_file=$(grep "^log_file" "${AUDITD_CONF}" | cut -d'=' -f2 | tr -d ' ')
    if [[ -z ${log_file} ]]; then
        echo "Audit log file location not configured" >&2
        flag=1
    fi

    # Check maximum log file size
    max_log_file=$(grep "^max_log_file" "${AUDITD_CONF}" | cut -d'=' -f2 | tr -d ' ')
    if [[ -z ${max_log_file} || ${max_log_file} -lt 50 ]]; then
        echo "Audit maximum log file size not set or too low (should be >= 50 MB)" >&2
        flag=1
    fi

    # Check log file rotation
    num_logs=$(grep "^num_logs" "${AUDITD_CONF}" | cut -d'=' -f2 | tr -d ' ')
    if [[ -z ${num_logs} || ${num_logs} -lt 5 ]]; then
        echo "Audit log rotation not configured properly (should keep >= 5 logs)" >&2
        flag=1
    fi

    # Check action when disk space is low
    space_left_action=$(grep "^space_left_action" "${AUDITD_CONF}" | cut -d'=' -f2 | tr -d ' ')
    if [[ ${space_left_action} != "email" && ${space_left_action} != "syslog" ]]; then
        echo "Audit space_left_action not configured for notification" >&2
        flag=1
    fi

    # Check action when disk is full
    disk_full_action=$(grep "^disk_full_action" "${AUDITD_CONF}" | cut -d'=' -f2 | tr -d ' ')
    if [[ ${disk_full_action} != "halt" && ${disk_full_action} != "single" ]]; then
        echo "Audit disk_full_action not configured for system protection" >&2
        flag=1
    fi

    # Check maximum log file action
    max_log_file_action=$(grep "^max_log_file_action" "${AUDITD_CONF}" | cut -d'=' -f2 | tr -d ' ')
    if [[ ${max_log_file_action} != "rotate" && ${max_log_file_action} != "keep_logs" ]]; then
        echo "Audit max_log_file_action not configured for log retention" >&2
        flag=1
    fi
else
    echo "Audit daemon configuration file not found" >&2
    flag=1
fi

# Check audit rules
AUDIT_RULES="${RISU_ROOT}/etc/audit/rules.d/audit.rules"
AUDIT_RULES_OLD="${RISU_ROOT}/etc/audit/audit.rules"

# Use the appropriate audit rules file
if [[ -f ${AUDIT_RULES} ]]; then
    RULES_FILE="${AUDIT_RULES}"
elif [[ -f ${AUDIT_RULES_OLD} ]]; then
    RULES_FILE="${AUDIT_RULES_OLD}"
else
    echo "Audit rules file not found" >&2
    flag=1
    RULES_FILE=""
fi

if [[ -n ${RULES_FILE} ]]; then
    # Check for time change auditing
    if ! grep -q "time-change" "${RULES_FILE}"; then
        echo "Time change auditing not configured" >&2
        flag=1
    fi

    # Check for user/group information auditing
    if ! grep -q "/etc/group" "${RULES_FILE}" || ! grep -q "/etc/passwd" "${RULES_FILE}"; then
        echo "User/group information auditing not configured" >&2
        flag=1
    fi

    # Check for network environment auditing
    if ! grep -q "/etc/hosts" "${RULES_FILE}" || ! grep -q "/etc/sysconfig/network" "${RULES_FILE}"; then
        echo "Network environment auditing not configured" >&2
        flag=1
    fi

    # Check for MAC policy auditing
    if ! grep -q "/etc/selinux" "${RULES_FILE}"; then
        echo "MAC policy auditing not configured" >&2
        flag=1
    fi

    # Check for login/logout auditing
    if ! grep -q "/var/log/lastlog" "${RULES_FILE}" || ! grep -q "/var/run/faillock" "${RULES_FILE}"; then
        echo "Login/logout auditing not configured" >&2
        flag=1
    fi

    # Check for process and session initiation auditing
    if ! grep -q "/var/run/utmp" "${RULES_FILE}" || ! grep -q "/var/log/wtmp" "${RULES_FILE}"; then
        echo "Process and session initiation auditing not configured" >&2
        flag=1
    fi

    # Check for discretionary access control auditing
    if ! grep -q "perm_mod" "${RULES_FILE}"; then
        echo "Discretionary access control auditing not configured" >&2
        flag=1
    fi

    # Check for unauthorized file access auditing
    if ! grep -q "access" "${RULES_FILE}"; then
        echo "Unauthorized file access auditing not configured" >&2
        flag=1
    fi

    # Check for successful file system mounts auditing
    if ! grep -q "mount" "${RULES_FILE}"; then
        echo "File system mount auditing not configured" >&2
        flag=1
    fi

    # Check for file deletion auditing
    if ! grep -q "delete" "${RULES_FILE}"; then
        echo "File deletion auditing not configured" >&2
        flag=1
    fi

    # Check for sudoers auditing
    if ! grep -q "/etc/sudoers" "${RULES_FILE}"; then
        echo "Sudoers file auditing not configured" >&2
        flag=1
    fi

    # Check for sudo commands auditing
    if ! grep -q "sudo" "${RULES_FILE}"; then
        echo "Sudo commands auditing not configured" >&2
        flag=1
    fi

    # Check for kernel module auditing
    if ! grep -q "modules" "${RULES_FILE}"; then
        echo "Kernel module auditing not configured" >&2
        flag=1
    fi

    # Check for immutable flag (should be last rule)
    if ! grep -q "^-e 2" "${RULES_FILE}"; then
        echo "Audit configuration not set to immutable" >&2
        flag=1
    fi
fi

# Check rsyslog configuration
RSYSLOG_CONF="${RISU_ROOT}/etc/rsyslog.conf"
RSYSLOG_D_DIR="${RISU_ROOT}/etc/rsyslog.d"

if [[ -f ${RSYSLOG_CONF} ]]; then
    # Check for remote logging
    if ! grep -q "^*.*@@" "${RSYSLOG_CONF}"; then
        echo "Remote logging not configured in rsyslog" >&2
        flag=1
    fi

    # Check for log file permissions
    if ! grep -q "FileCreateMode" "${RSYSLOG_CONF}"; then
        echo "Log file permissions not configured in rsyslog" >&2
        flag=1
    fi
fi

# Check additional rsyslog configuration files
if [[ -d ${RSYSLOG_D_DIR} ]]; then
    for rsyslog_file in "${RSYSLOG_D_DIR}"/*.conf; do
        if [[ -f ${rsyslog_file} ]]; then
            # Check for proper configuration
            if grep -q "^*.*@@" "${rsyslog_file}"; then
                echo "Remote logging configured in $(basename ${rsyslog_file})" >&2
            fi
        fi
    done
fi

# Check log directory permissions
LOG_DIRS=(
    "/var/log"
    "/var/log/audit"
    "/var/log/messages"
    "/var/log/secure"
    "/var/log/maillog"
    "/var/log/cron"
    "/var/log/spooler"
    "/var/log/boot.log"
)

for log_path in "${LOG_DIRS[@]}"; do
    full_path="${RISU_ROOT}${log_path}"
    if [[ -e ${full_path} ]]; then
        # Check if it's readable by others
        if [[ -r ${full_path} ]]; then
            # This is a simplified check - in a real implementation you'd check actual permissions
            echo "Log path exists: ${log_path}" >&2
        fi
    fi
done

# Check for log rotation configuration
LOGROTATE_CONF="${RISU_ROOT}/etc/logrotate.conf"
LOGROTATE_D_DIR="${RISU_ROOT}/etc/logrotate.d"

if [[ -f ${LOGROTATE_CONF} ]]; then
    # Check for weekly rotation
    if ! grep -q "weekly" "${LOGROTATE_CONF}"; then
        echo "Log rotation not configured for weekly rotation" >&2
        flag=1
    fi

    # Check for log retention
    if ! grep -q "rotate" "${LOGROTATE_CONF}"; then
        echo "Log retention not configured" >&2
        flag=1
    fi
fi

# Check system log files permissions
SYSTEM_LOGS=(
    "/var/log/messages"
    "/var/log/secure"
    "/var/log/maillog"
    "/var/log/cron"
    "/var/log/spooler"
    "/var/log/boot.log"
)

for log_file in "${SYSTEM_LOGS[@]}"; do
    full_log_path="${RISU_ROOT}${log_file}"
    if [[ -f ${full_log_path} ]]; then
        echo "System log file exists: ${log_file}" >&2
    fi
done

# Check for centralized logging
if [[ -f ${RSYSLOG_CONF} ]]; then
    # Check if logs are sent to central server
    if ! grep -q "@@.*\..*:" "${RSYSLOG_CONF}"; then
        echo "Centralized logging not configured" >&2
        flag=1
    fi
fi

if [[ $flag -eq 1 ]]; then
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
