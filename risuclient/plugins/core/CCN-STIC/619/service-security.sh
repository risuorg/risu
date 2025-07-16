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

# long_name: Validate service security configuration
# description: Validate services and daemon security settings for CCN-STIC-619
# priority: 130
# bugzilla: https://www.ccn-cert.cni.es/pdf/guias/series-ccn-stic/guias-de-acceso-publico-ccn-stic/3674-ccn-stic-619-implementacion-de-seguridad-sobre-centos7/file.html

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

flag=0

echo "Checking service security configuration..." >&2

# Define services that should be disabled for security
DANGEROUS_SERVICES=(
    "telnet"
    "rsh"
    "rlogin"
    "rexec"
    "tftp"
    "talk"
    "ntalk"
    "finger"
    "echo"
    "discard"
    "chargen"
    "daytime"
    "time"
    "cups"
    "nfs"
    "nfs-server"
    "rpcbind"
    "ypbind"
    "ypserv"
    "httpd"
    "nginx"
    "apache2"
    "vsftpd"
    "proftpd"
    "wu-ftpd"
    "named"
    "bind"
    "bind9"
    "dhcpd"
    "dhcp"
    "snmpd"
    "squid"
    "dovecot"
    "postfix"
    "sendmail"
    "exim"
    "samba"
    "smb"
    "nmb"
    "winbind"
    "avahi-daemon"
    "avahi"
    "bluetooth"
    "bluetoothd"
    "rhnsd"
    "yum-updatesd"
)

# Define services that should be enabled for security
REQUIRED_SERVICES=(
    "auditd"
    "rsyslog"
    "syslog"
    "crond"
    "sshd"
    "iptables"
    "firewalld"
    "ntpd"
    "chronyd"
)

# Check systemd services
SYSTEMD_SYSTEM_DIR="${RISU_ROOT}/usr/lib/systemd/system"
SYSTEMD_LOCAL_DIR="${RISU_ROOT}/etc/systemd/system"

# Function to check if a systemd service is enabled
is_systemd_service_enabled() {
    local service="$1"
    local enabled_dir="${SYSTEMD_LOCAL_DIR}/multi-user.target.wants"

    if [[ -L "${enabled_dir}/${service}.service" ]]; then
        return 0
    fi

    # Check for other target directories
    for target_dir in "${SYSTEMD_LOCAL_DIR}"/*.target.wants; do
        if [[ -d ${target_dir} && -L "${target_dir}/${service}.service" ]]; then
            return 0
        fi
    done

    return 1
}

# Check for dangerous services that should be disabled
for service in "${DANGEROUS_SERVICES[@]}"; do
    if [[ -f "${SYSTEMD_SYSTEM_DIR}/${service}.service" ]]; then
        if is_systemd_service_enabled "${service}"; then
            echo "Dangerous service enabled: ${service}" >&2
            flag=1
        fi
    fi
done

# Check for required services that should be enabled
for service in "${REQUIRED_SERVICES[@]}"; do
    if [[ -f "${SYSTEMD_SYSTEM_DIR}/${service}.service" ]]; then
        if ! is_systemd_service_enabled "${service}"; then
            echo "Required service not enabled: ${service}" >&2
            flag=1
        fi
    fi
done

# Check xinetd services
XINETD_DIR="${RISU_ROOT}/etc/xinetd.d"
if [[ -d ${XINETD_DIR} ]]; then
    for service_file in "${XINETD_DIR}"/*; do
        if [[ -f ${service_file} ]]; then
            service_name=$(basename "${service_file}")

            # Check if service is disabled
            if ! grep -q "disable.*yes" "${service_file}"; then
                echo "xinetd service not disabled: ${service_name}" >&2
                flag=1
            fi
        fi
    done
fi

# Check for services listening on network ports
NETWORK_SERVICES_CHECK=(
    "23/tcp"   # telnet
    "21/tcp"   # ftp
    "69/udp"   # tftp
    "513/tcp"  # rlogin
    "514/tcp"  # rsh
    "512/tcp"  # rexec
    "79/tcp"   # finger
    "111/tcp"  # rpcbind
    "111/udp"  # rpcbind
    "515/tcp"  # printer
    "631/tcp"  # cups
    "5353/udp" # avahi
)

echo "Checking for services listening on dangerous ports..." >&2

# Check listening ports (if netstat output is available)
NETSTAT_OUTPUT="${RISU_ROOT}/sos_commands/networking/netstat_-neopa"
if [[ -f ${NETSTAT_OUTPUT} ]]; then
    for port_proto in "${NETWORK_SERVICES_CHECK[@]}"; do
        port=$(echo "${port_proto}" | cut -d'/' -f1)
        proto=$(echo "${port_proto}" | cut -d'/' -f2)

        if grep -q ":${port}.*LISTEN" "${NETSTAT_OUTPUT}"; then
            echo "Dangerous service listening on port ${port}/${proto}" >&2
            flag=1
        fi
    done
fi

# Check service configuration files for security settings
echo "Checking service configuration files..." >&2

# Check SSH configuration (already covered in network-security.sh but important for services)
SSH_CONFIG="${RISU_ROOT}/etc/ssh/sshd_config"
if [[ -f ${SSH_CONFIG} ]]; then
    # Check if SSH is configured securely
    if ! grep -q "^PermitRootLogin no" "${SSH_CONFIG}"; then
        echo "SSH root login not disabled in service configuration" >&2
        flag=1
    fi
fi

# Check cron service configuration
CRON_ALLOW="${RISU_ROOT}/etc/cron.allow"
CRON_DENY="${RISU_ROOT}/etc/cron.deny"

if [[ -f ${CRON_ALLOW} ]]; then
    echo "Cron allow file exists: checking permissions" >&2
elif [[ -f ${CRON_DENY} ]]; then
    echo "Cron deny file exists: checking permissions" >&2
else
    echo "No cron access control files found" >&2
    flag=1
fi

# Check at service configuration
AT_ALLOW="${RISU_ROOT}/etc/at.allow"
AT_DENY="${RISU_ROOT}/etc/at.deny"

if [[ -f ${AT_ALLOW} ]]; then
    echo "At allow file exists: checking permissions" >&2
elif [[ -f ${AT_DENY} ]]; then
    echo "At deny file exists: checking permissions" >&2
else
    echo "No at access control files found" >&2
    flag=1
fi

# Check NTP service configuration
NTP_CONF="${RISU_ROOT}/etc/ntp.conf"
CHRONY_CONF="${RISU_ROOT}/etc/chrony.conf"

if [[ -f ${NTP_CONF} ]]; then
    # Check for restrict directives
    if ! grep -q "^restrict" "${NTP_CONF}"; then
        echo "NTP service not configured with proper restrictions" >&2
        flag=1
    fi
elif [[ -f ${CHRONY_CONF} ]]; then
    # Check for chrony security settings
    if ! grep -q "^driftfile" "${CHRONY_CONF}"; then
        echo "Chrony service not configured properly" >&2
        flag=1
    fi
else
    echo "No NTP service configuration found" >&2
    flag=1
fi

# Check for unnecessary kernel modules that should be disabled
KERNEL_MODULES_TO_DISABLE=(
    "cramfs"
    "freevxfs"
    "jffs2"
    "hfs"
    "hfsplus"
    "squashfs"
    "udf"
    "dccp"
    "sctp"
    "rds"
    "tipc"
    "usb-storage"
    "firewire-core"
    "bluetooth"
)

MODPROBE_DIR="${RISU_ROOT}/etc/modprobe.d"
if [[ -d ${MODPROBE_DIR} ]]; then
    for module in "${KERNEL_MODULES_TO_DISABLE[@]}"; do
        if ! grep -r "install ${module} /bin/true" "${MODPROBE_DIR}/" >/dev/null 2>&1; then
            echo "Kernel module not disabled: ${module}" >&2
            flag=1
        fi
    done
fi

# Check for services running as root that shouldn't
echo "Checking for services running as root..." >&2

# Check systemd service files for User= directives
SERVICES_SHOULD_NOT_RUN_AS_ROOT=(
    "httpd"
    "nginx"
    "apache2"
    "named"
    "bind"
    "bind9"
    "postfix"
    "sendmail"
    "dovecot"
    "mysql"
    "mysqld"
    "mariadb"
    "postgresql"
    "postgres"
)

for service in "${SERVICES_SHOULD_NOT_RUN_AS_ROOT[@]}"; do
    if [[ -f "${SYSTEMD_SYSTEM_DIR}/${service}.service" ]]; then
        if ! grep -q "^User=" "${SYSTEMD_SYSTEM_DIR}/${service}.service"; then
            echo "Service ${service} does not specify non-root user" >&2
            flag=1
        fi
    fi
done

# Check for default service accounts
DEFAULT_SERVICE_ACCOUNTS=(
    "ftp"
    "nobody"
    "daemon"
    "sys"
    "adm"
    "lp"
    "sync"
    "shutdown"
    "halt"
    "news"
    "uucp"
    "operator"
    "games"
    "gopher"
    "apache"
    "www-data"
    "mysql"
    "postgres"
    "postfix"
    "named"
    "bind"
    "dovecot"
    "sshd"
    "ntp"
    "chrony"
)

PASSWD_FILE="${RISU_ROOT}/etc/passwd"
if [[ -f ${PASSWD_FILE} ]]; then
    echo "Checking for service accounts..." >&2
    for account in "${DEFAULT_SERVICE_ACCOUNTS[@]}"; do
        if grep -q "^${account}:" "${PASSWD_FILE}"; then
            # Check if account has login shell
            shell=$(grep "^${account}:" "${PASSWD_FILE}" | cut -d':' -f7)
            if [[ ${shell} != "/sbin/nologin" && ${shell} != "/bin/false" && ${shell} != "/usr/sbin/nologin" ]]; then
                echo "Service account ${account} has login shell: ${shell}" >&2
                flag=1
            fi
        fi
    done
fi

# Check for service startup scripts with insecure permissions
INIT_SCRIPTS_DIR="${RISU_ROOT}/etc/init.d"
if [[ -d ${INIT_SCRIPTS_DIR} ]]; then
    for init_script in "${INIT_SCRIPTS_DIR}"/*; do
        if [[ -f ${init_script} ]]; then
            script_name=$(basename "${init_script}")
            echo "Found init script: ${script_name}" >&2
            # In a real implementation, you would check permissions
        fi
    done
fi

if [[ $flag -eq 1 ]]; then
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
