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

# long_name: Validate systemd security configuration for RHEL 9
# description: Validate systemd security settings for CCN-STIC-610A22
# priority: 890
# bugzilla: https://www.ccn-cert.cni.es/pdf/guias/series-ccn-stic/guias-de-acceso-publico-ccn-stic/6768-ccn-stic-610a22-perfilado-de-seguridad-red-hat-enterprise-linux-9-0/file.html

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

flag=0

echo "Checking systemd security configuration..." >&2

# Check systemd system configuration
SYSTEMD_SYSTEM_CONF="${RISU_ROOT}/etc/systemd/system.conf"
SYSTEMD_USER_CONF="${RISU_ROOT}/etc/systemd/user.conf"

if [[ -f ${SYSTEMD_SYSTEM_CONF} ]]; then
    echo "Checking systemd system configuration..." >&2

    # Check for DumpCore setting
    if ! grep -q "^DumpCore=no" "${SYSTEMD_SYSTEM_CONF}"; then
        echo "SystemD DumpCore not disabled" >&2
        flag=1
    fi

    # Check for DefaultLimitCORE setting
    if ! grep -q "^DefaultLimitCORE=0" "${SYSTEMD_SYSTEM_CONF}"; then
        echo "SystemD DefaultLimitCORE not set to 0" >&2
        flag=1
    fi

    # Check for DefaultTimeoutStopSec
    if ! grep -q "^DefaultTimeoutStopSec=" "${SYSTEMD_SYSTEM_CONF}"; then
        echo "SystemD DefaultTimeoutStopSec not configured" >&2
        flag=1
    fi

    # Check for DefaultRestartSec
    if ! grep -q "^DefaultRestartSec=" "${SYSTEMD_SYSTEM_CONF}"; then
        echo "SystemD DefaultRestartSec not configured" >&2
        flag=1
    fi
fi

# Check systemd service hardening
SYSTEMD_SYSTEM_DIR="${RISU_ROOT}/usr/lib/systemd/system"
SYSTEMD_LOCAL_DIR="${RISU_ROOT}/etc/systemd/system"

# Services that should have security hardening
SERVICES_TO_CHECK=(
    "httpd.service"
    "nginx.service"
    "mysql.service"
    "postgresql.service"
    "mariadb.service"
    "named.service"
    "bind9.service"
    "postfix.service"
    "dovecot.service"
    "vsftpd.service"
    "proftpd.service"
    "samba.service"
    "smb.service"
    "nmb.service"
    "cups.service"
    "avahi-daemon.service"
    "bluetooth.service"
    "rpcbind.service"
    "nfs-server.service"
    "dhcpd.service"
    "snmpd.service"
    "telnet.service"
    "rsh.service"
    "rlogin.service"
    "rexec.service"
    "tftp.service"
    "talk.service"
    "finger.service"
)

# Security hardening directives to check
SECURITY_DIRECTIVES=(
    "NoNewPrivileges"
    "PrivateTmp"
    "PrivateDevices"
    "ProtectSystem"
    "ProtectHome"
    "ReadOnlyPaths"
    "InaccessiblePaths"
    "CapabilityBoundingSet"
    "AmbientCapabilities"
    "User"
    "Group"
    "DynamicUser"
    "ProtectKernelTunables"
    "ProtectKernelModules"
    "ProtectControlGroups"
    "RestrictRealtime"
    "RestrictSUIDSGID"
    "RemoveIPC"
    "PrivateNetwork"
    "RestrictAddressFamilies"
    "RestrictNamespaces"
    "LockPersonality"
    "MemoryDenyWriteExecute"
    "RestrictRealtime"
    "SystemCallFilter"
    "SystemCallArchitectures"
)

for service in "${SERVICES_TO_CHECK[@]}"; do
    service_file=""

    # Check in system directory first
    if [[ -f "${SYSTEMD_SYSTEM_DIR}/${service}" ]]; then
        service_file="${SYSTEMD_SYSTEM_DIR}/${service}"
    elif [[ -f "${SYSTEMD_LOCAL_DIR}/${service}" ]]; then
        service_file="${SYSTEMD_LOCAL_DIR}/${service}"
    fi

    if [[ -n ${service_file} ]]; then
        echo "Checking security hardening for: ${service}" >&2

        # Check for basic security directives
        if ! grep -q "^NoNewPrivileges=true" "${service_file}"; then
            echo "Service ${service} does not have NoNewPrivileges enabled" >&2
            flag=1
        fi

        if ! grep -q "^PrivateTmp=true" "${service_file}"; then
            echo "Service ${service} does not have PrivateTmp enabled" >&2
            flag=1
        fi

        if ! grep -q "^ProtectSystem=" "${service_file}"; then
            echo "Service ${service} does not have ProtectSystem configured" >&2
            flag=1
        fi

        if ! grep -q "^ProtectHome=" "${service_file}"; then
            echo "Service ${service} does not have ProtectHome configured" >&2
            flag=1
        fi

        # Check for User directive (should not run as root)
        if ! grep -q "^User=" "${service_file}"; then
            echo "Service ${service} does not specify non-root user" >&2
            flag=1
        fi

        # Check for dangerous capabilities
        if grep -q "^CapabilityBoundingSet=.*CAP_SYS_ADMIN" "${service_file}"; then
            echo "Service ${service} has dangerous capability CAP_SYS_ADMIN" >&2
            flag=1
        fi

        if grep -q "^AmbientCapabilities=" "${service_file}"; then
            echo "Service ${service} has ambient capabilities (potential security risk)" >&2
            flag=1
        fi

        # Check for memory protection
        if ! grep -q "^MemoryDenyWriteExecute=true" "${service_file}"; then
            echo "Service ${service} does not have MemoryDenyWriteExecute enabled" >&2
            flag=1
        fi

        # Check for system call filtering
        if ! grep -q "^SystemCallFilter=" "${service_file}"; then
            echo "Service ${service} does not have SystemCallFilter configured" >&2
            flag=1
        fi

        # Check for namespace restrictions
        if ! grep -q "^RestrictNamespaces=" "${service_file}"; then
            echo "Service ${service} does not have RestrictNamespaces configured" >&2
            flag=1
        fi

        # Check for address family restrictions
        if ! grep -q "^RestrictAddressFamilies=" "${service_file}"; then
            echo "Service ${service} does not have RestrictAddressFamilies configured" >&2
            flag=1
        fi
    fi
done

# Check for services that should be disabled
SERVICES_TO_DISABLE=(
    "telnet.service"
    "rsh.service"
    "rlogin.service"
    "rexec.service"
    "tftp.service"
    "talk.service"
    "finger.service"
    "avahi-daemon.service"
    "bluetooth.service"
    "cups.service"
    "nfs-server.service"
    "rpcbind.service"
    "ypbind.service"
    "ypserv.service"
)

for service in "${SERVICES_TO_DISABLE[@]}"; do
    # Check if service is enabled
    enabled_file="${SYSTEMD_LOCAL_DIR}/multi-user.target.wants/${service}"
    if [[ -L ${enabled_file} ]]; then
        echo "Dangerous service enabled: ${service}" >&2
        flag=1
    fi

    # Check other target directories
    for target_dir in "${SYSTEMD_LOCAL_DIR}"/*.target.wants; do
        if [[ -d ${target_dir} && -L "${target_dir}/${service}" ]]; then
            echo "Dangerous service enabled in $(basename ${target_dir}): ${service}" >&2
            flag=1
        fi
    done
done

# Check for services that should be enabled
SERVICES_TO_ENABLE=(
    "auditd.service"
    "rsyslog.service"
    "crond.service"
    "sshd.service"
    "firewalld.service"
    "chronyd.service"
    "systemd-journald.service"
    "systemd-logind.service"
    "fapolicyd.service"
)

for service in "${SERVICES_TO_ENABLE[@]}"; do
    # Check if service is enabled
    enabled_file="${SYSTEMD_LOCAL_DIR}/multi-user.target.wants/${service}"
    if [[ ! -L ${enabled_file} ]]; then
        # Check other target directories
        service_enabled=false
        for target_dir in "${SYSTEMD_LOCAL_DIR}"/*.target.wants; do
            if [[ -d ${target_dir} && -L "${target_dir}/${service}" ]]; then
                service_enabled=true
                break
            fi
        done

        if [[ ${service_enabled} == "false" ]]; then
            echo "Required service not enabled: ${service}" >&2
            flag=1
        fi
    fi
done

# Check systemd-journald configuration
JOURNALD_CONF="${RISU_ROOT}/etc/systemd/journald.conf"
if [[ -f ${JOURNALD_CONF} ]]; then
    echo "Checking systemd-journald configuration..." >&2

    # Check for persistent logging
    if ! grep -q "^Storage=persistent" "${JOURNALD_CONF}"; then
        echo "Journal logging not configured for persistent storage" >&2
        flag=1
    fi

    # Check for compression
    if ! grep -q "^Compress=yes" "${JOURNALD_CONF}"; then
        echo "Journal compression not enabled" >&2
        flag=1
    fi

    # Check for rate limiting
    if ! grep -q "^RateLimitInterval=" "${JOURNALD_CONF}"; then
        echo "Journal rate limiting not configured" >&2
        flag=1
    fi

    # Check for forward to syslog
    if ! grep -q "^ForwardToSyslog=yes" "${JOURNALD_CONF}"; then
        echo "Journal forwarding to syslog not enabled" >&2
        flag=1
    fi

    # Check for sealing
    if ! grep -q "^Seal=yes" "${JOURNALD_CONF}"; then
        echo "Journal sealing not enabled" >&2
        flag=1
    fi
fi

# Check systemd-logind configuration
LOGIND_CONF="${RISU_ROOT}/etc/systemd/logind.conf"
if [[ -f ${LOGIND_CONF} ]]; then
    echo "Checking systemd-logind configuration..." >&2

    # Check for kill user processes
    if ! grep -q "^KillUserProcesses=yes" "${LOGIND_CONF}"; then
        echo "User processes not configured to be killed on logout" >&2
        flag=1
    fi

    # Check for idle action
    if ! grep -q "^IdleAction=" "${LOGIND_CONF}"; then
        echo "Idle action not configured" >&2
        flag=1
    fi

    # Check for idle action timeout
    if ! grep -q "^IdleActionSec=" "${LOGIND_CONF}"; then
        echo "Idle action timeout not configured" >&2
        flag=1
    fi
fi

# Check systemd-resolved configuration
RESOLVED_CONF="${RISU_ROOT}/etc/systemd/resolved.conf"
if [[ -f ${RESOLVED_CONF} ]]; then
    echo "Checking systemd-resolved configuration..." >&2

    # Check for DNS over TLS
    if ! grep -q "^DNS=" "${RESOLVED_CONF}"; then
        echo "DNS servers not configured in resolved.conf" >&2
        flag=1
    fi

    # Check for DNSSEC
    if ! grep -q "^DNSSEC=yes" "${RESOLVED_CONF}"; then
        echo "DNSSEC not enabled in resolved.conf" >&2
        flag=1
    fi

    # Check for DNS over TLS
    if ! grep -q "^DNSOverTLS=yes" "${RESOLVED_CONF}"; then
        echo "DNS over TLS not enabled in resolved.conf" >&2
        flag=1
    fi
fi

# Check for systemd timers (should be used instead of cron for some tasks)
SYSTEMD_TIMERS_DIR="${RISU_ROOT}/etc/systemd/system"
if [[ -d ${SYSTEMD_TIMERS_DIR} ]]; then
    echo "Checking systemd timers..." >&2

    # Check for security update timers
    if [[ ! -f "${SYSTEMD_TIMERS_DIR}/security-updates.timer" ]]; then
        echo "No security updates timer found" >&2
        flag=1
    fi

    # Check for system backup timers
    if [[ ! -f "${SYSTEMD_TIMERS_DIR}/system-backup.timer" ]]; then
        echo "No system backup timer found" >&2
        flag=1
    fi
fi

# Check for systemd-coredump configuration
COREDUMP_CONF="${RISU_ROOT}/etc/systemd/coredump.conf"
if [[ -f ${COREDUMP_CONF} ]]; then
    echo "Checking systemd-coredump configuration..." >&2

    # Check for storage setting
    if ! grep -q "^Storage=none" "${COREDUMP_CONF}"; then
        echo "Core dump storage not disabled" >&2
        flag=1
    fi

    # Check for processing setting
    if ! grep -q "^ProcessSizeMax=0" "${COREDUMP_CONF}"; then
        echo "Core dump processing not disabled" >&2
        flag=1
    fi
fi

if [[ $flag -eq 1 ]]; then
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
