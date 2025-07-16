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

# long_name: Validate network security configuration
# description: Validate network security settings for CCN-STIC-619
# priority: 870
# bugzilla: https://www.ccn-cert.cni.es/pdf/guias/series-ccn-stic/guias-de-acceso-publico-ccn-stic/3674-ccn-stic-619-implementacion-de-seguridad-sobre-centos7/file.html

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

# Function is now available in common functions

flag=0

echo "Checking network security configuration..." >&2

# Check firewall configuration
FIREWALL_CONFIG="${RISU_ROOT}/etc/sysconfig/iptables"
FIREWALLD_CONFIG="${RISU_ROOT}/etc/firewalld"

# Check if firewall is configured
if [[ ! -f ${FIREWALL_CONFIG} && ! -d ${FIREWALLD_CONFIG} ]]; then
    echo "No firewall configuration found (neither iptables nor firewalld)" >&2
    flag=1
else
    echo "Firewall configuration found" >&2
fi

# Check for dangerous network services
DANGEROUS_SERVICES=(
    "telnet"
    "rsh"
    "rlogin"
    "rexec"
    "ftp"
    "tftp"
    "finger"
    "talk"
    "ntalk"
    "echo"
    "discard"
    "chargen"
    "daytime"
    "time"
)

XINETD_DIR="${RISU_ROOT}/etc/xinetd.d"
if [[ -d ${XINETD_DIR} ]]; then
    for service in "${DANGEROUS_SERVICES[@]}"; do
        if [[ -f "${XINETD_DIR}/${service}" ]]; then
            # Check if service is enabled
            if ! grep -q "disable.*yes" "${XINETD_DIR}/${service}"; then
                echo "Dangerous network service enabled: ${service}" >&2
                flag=1
            fi
        fi
    done
fi

# Check systemd services
SYSTEMD_DIR="${RISU_ROOT}/etc/systemd/system"
SYSTEMD_SYSTEM_DIR="${RISU_ROOT}/usr/lib/systemd/system"

for service in "${DANGEROUS_SERVICES[@]}"; do
    for dir in "${SYSTEMD_DIR}" "${SYSTEMD_SYSTEM_DIR}"; do
        if [[ -f "${dir}/${service}.service" ]]; then
            # Check if service is enabled by looking for symlinks
            if [[ -L "${SYSTEMD_DIR}/multi-user.target.wants/${service}.service" ]]; then
                echo "Dangerous systemd service enabled: ${service}" >&2
                flag=1
            fi
        fi
    done
done

# Check SSH configuration
SSH_CONFIG="${RISU_ROOT}/etc/ssh/sshd_config"
if [[ -f ${SSH_CONFIG} ]]; then
    # Check SSH protocol version
    if grep -q "^Protocol 1" "${SSH_CONFIG}"; then
        echo "SSH Protocol 1 is enabled (insecure)" >&2
        flag=1
    fi

    # Check root login
    if grep -q "^PermitRootLogin yes" "${SSH_CONFIG}"; then
        echo "SSH root login is enabled" >&2
        flag=1
    fi

    # Check empty passwords
    if grep -q "^PermitEmptyPasswords yes" "${SSH_CONFIG}"; then
        echo "SSH empty passwords are allowed" >&2
        flag=1
    fi

    # Check X11 forwarding
    if grep -q "^X11Forwarding yes" "${SSH_CONFIG}"; then
        echo "SSH X11 forwarding is enabled (potential security risk)" >&2
    fi

    # Check for strong ciphers
    if grep -q "^Ciphers" "${SSH_CONFIG}"; then
        ciphers=$(grep "^Ciphers" "${SSH_CONFIG}" | cut -d' ' -f2-)
        if [[ ${ciphers} == *"3des"* || ${ciphers} == *"des"* ]]; then
            echo "SSH weak ciphers detected: ${ciphers}" >&2
            flag=1
        fi
    fi

    # Check MaxAuthTries
    max_auth_tries=$(grep "^MaxAuthTries" "${SSH_CONFIG}" | awk '{print $2}')
    if [[ -n ${max_auth_tries} && ${max_auth_tries} -gt 3 ]]; then
        echo "SSH MaxAuthTries is too high: ${max_auth_tries}" >&2
        flag=1
    fi
fi

# Check network interfaces configuration
NETWORK_SCRIPTS="${RISU_ROOT}/etc/sysconfig/network-scripts"
if [[ -d ${NETWORK_SCRIPTS} ]]; then
    for ifcfg in "${NETWORK_SCRIPTS}"/ifcfg-*; do
        if [[ -f ${ifcfg} ]]; then
            # Check for promiscuous mode
            if grep -q "^PROMISC=yes" "${ifcfg}"; then
                echo "Network interface in promiscuous mode: $(basename ${ifcfg})" >&2
                flag=1
            fi

            # Check for IP forwarding on interface
            if grep -q "^IPV4_FORWARDING=yes" "${ifcfg}"; then
                echo "IP forwarding enabled on interface: $(basename ${ifcfg})" >&2
                flag=1
            fi
        fi
    done
fi

# Check hosts.allow and hosts.deny
HOSTS_ALLOW="${RISU_ROOT}/etc/hosts.allow"
HOSTS_DENY="${RISU_ROOT}/etc/hosts.deny"

if [[ -f ${HOSTS_ALLOW} ]]; then
    # Check for overly permissive rules
    if grep -q "ALL: ALL" "${HOSTS_ALLOW}"; then
        echo "Overly permissive hosts.allow rule found: ALL: ALL" >&2
        flag=1
    fi
fi

if [[ -f ${HOSTS_DENY} ]]; then
    # Check if hosts.deny has appropriate restrictions
    if ! grep -q "ALL: ALL" "${HOSTS_DENY}"; then
        echo "hosts.deny should contain 'ALL: ALL' as default deny rule" >&2
        flag=1
    fi
fi

# Check for IPv6 configuration if disabled
IPV6_DISABLED=$(get_sysctl_value "net.ipv6.conf.all.disable_ipv6")
if [[ ${IPV6_DISABLED} == "1" ]]; then
    # Check if IPv6 modules are blacklisted
    MODPROBE_DIR="${RISU_ROOT}/etc/modprobe.d"
    if [[ -d ${MODPROBE_DIR} ]]; then
        if ! grep -r "blacklist ipv6" "${MODPROBE_DIR}/" >/dev/null 2>&1; then
            echo "IPv6 disabled in sysctl but not blacklisted in modprobe" >&2
            flag=1
        fi
    fi
fi

# Check for unused network protocols
PROTOCOLS_TO_CHECK=(
    "dccp"
    "sctp"
    "rds"
    "tipc"
)

for protocol in "${PROTOCOLS_TO_CHECK[@]}"; do
    if [[ -f "${RISU_ROOT}/etc/modprobe.d/blacklist-${protocol}.conf" ]]; then
        if ! grep -q "blacklist ${protocol}" "${RISU_ROOT}/etc/modprobe.d/blacklist-${protocol}.conf"; then
            echo "Protocol ${protocol} should be blacklisted" >&2
            flag=1
        fi
    else
        echo "Protocol ${protocol} not blacklisted (create /etc/modprobe.d/blacklist-${protocol}.conf)" >&2
        flag=1
    fi
done

if [[ $flag -eq 1 ]]; then
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
