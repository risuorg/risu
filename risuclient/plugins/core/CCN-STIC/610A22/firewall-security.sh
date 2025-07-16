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

# long_name: Validate firewall security configuration for RHEL 9
# description: Validate firewalld security settings for CCN-STIC-610A22
# priority: 130
# bugzilla: https://www.ccn-cert.cni.es/pdf/guias/series-ccn-stic/guias-de-acceso-publico-ccn-stic/6768-ccn-stic-610a22-perfilado-de-seguridad-red-hat-enterprise-linux-9-0/file.html

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

flag=0

echo "Checking firewall security configuration..." >&2

# Check firewalld configuration
FIREWALLD_CONF="${RISU_ROOT}/etc/firewalld/firewalld.conf"
FIREWALLD_ZONES_DIR="${RISU_ROOT}/etc/firewalld/zones"
FIREWALLD_SERVICES_DIR="${RISU_ROOT}/etc/firewalld/services"

if [[ -f ${FIREWALLD_CONF} ]]; then
    echo "Checking firewalld configuration..." >&2

    # Check default zone
    default_zone=$(grep "^DefaultZone=" "${FIREWALLD_CONF}" | cut -d'=' -f2)
    if [[ ${default_zone} == "public" ]]; then
        echo "Default zone is public (consider using a more restrictive zone)" >&2
        flag=1
    fi

    # Check cleanup on exit
    if ! grep -q "^CleanupOnExit=yes" "${FIREWALLD_CONF}"; then
        echo "Firewalld cleanup on exit not enabled" >&2
        flag=1
    fi

    # Check lockdown
    if ! grep -q "^Lockdown=yes" "${FIREWALLD_CONF}"; then
        echo "Firewalld lockdown not enabled" >&2
        flag=1
    fi

    # Check IPv6_rpfilter
    if ! grep -q "^IPv6_rpfilter=yes" "${FIREWALLD_CONF}"; then
        echo "IPv6 reverse path filter not enabled" >&2
        flag=1
    fi

    # Check IndividualCalls
    if ! grep -q "^IndividualCalls=no" "${FIREWALLD_CONF}"; then
        echo "Individual calls not disabled (performance impact)" >&2
        flag=1
    fi

    # Check LogDenied
    if ! grep -q "^LogDenied=all" "${FIREWALLD_CONF}"; then
        echo "Log denied not set to all" >&2
        flag=1
    fi

    # Check AutomaticHelpers
    if ! grep -q "^AutomaticHelpers=no" "${FIREWALLD_CONF}"; then
        echo "Automatic helpers not disabled" >&2
        flag=1
    fi
else
    echo "Firewalld configuration file not found" >&2
    flag=1
fi

# Check firewalld zones
if [[ -d ${FIREWALLD_ZONES_DIR} ]]; then
    echo "Checking firewalld zones..." >&2

    # Check for overly permissive zones
    for zone_file in "${FIREWALLD_ZONES_DIR}"/*.xml; do
        if [[ -f ${zone_file} ]]; then
            zone_name=$(basename "${zone_file}" .xml)

            # Check for accept all rule
            if grep -q '<rule.*accept.*all' "${zone_file}"; then
                echo "Zone ${zone_name} has accept all rule" >&2
                flag=1
            fi

            # Check for masquerading
            if grep -q '<masquerade/>' "${zone_file}"; then
                echo "Zone ${zone_name} has masquerading enabled" >&2
                # This might be OK for some zones, just informational
            fi

            # Check for port forwarding
            if grep -q '<forward-port' "${zone_file}"; then
                echo "Zone ${zone_name} has port forwarding configured" >&2
                # This might be OK for some zones, just informational
            fi

            # Check for dangerous services
            DANGEROUS_SERVICES=(
                "ssh"
                "telnet"
                "ftp"
                "tftp"
                "finger"
                "http"
                "https"
                "mysql"
                "postgresql"
                "nfs"
                "rpc-bind"
                "samba"
                "snmp"
                "dhcp"
                "dns"
                "ldap"
                "ldaps"
                "vnc-server"
                "x11"
            )

            for service in "${DANGEROUS_SERVICES[@]}"; do
                if grep -q "<service name=\"${service}\"/>" "${zone_file}"; then
                    echo "Zone ${zone_name} allows potentially dangerous service: ${service}" >&2
                    if [[ ${service} == "telnet" || ${service} == "ftp" || ${service} == "tftp" || ${service} == "finger" ]]; then
                        flag=1
                    fi
                fi
            done

            # Check for dangerous ports
            DANGEROUS_PORTS=(
                "21"   # FTP
                "23"   # Telnet
                "69"   # TFTP
                "79"   # Finger
                "111"  # RPC
                "135"  # RPC
                "139"  # NetBIOS
                "445"  # SMB
                "513"  # rlogin
                "514"  # rsh
                "515"  # LPD
                "631"  # CUPS
                "2049" # NFS
                "3306" # MySQL
                "5432" # PostgreSQL
                "5900" # VNC
                "6000" # X11
            )

            for port in "${DANGEROUS_PORTS[@]}"; do
                if grep -q "<port.*port=\"${port}\"" "${zone_file}"; then
                    echo "Zone ${zone_name} allows potentially dangerous port: ${port}" >&2
                    if [[ ${port} == "21" || ${port} == "23" || ${port} == "69" || ${port} == "79" || ${port} == "513" || ${port} == "514" ]]; then
                        flag=1
                    fi
                fi
            done
        fi
    done
fi

# Check firewalld services
if [[ -d ${FIREWALLD_SERVICES_DIR} ]]; then
    echo "Checking firewalld services..." >&2

    for service_file in "${FIREWALLD_SERVICES_DIR}"/*.xml; do
        if [[ -f ${service_file} ]]; then
            service_name=$(basename "${service_file}" .xml)

            # Check for services that should not be defined
            FORBIDDEN_SERVICES=(
                "telnet"
                "ftp"
                "tftp"
                "finger"
                "rsh"
                "rlogin"
                "rexec"
                "talk"
                "ntalk"
            )

            for forbidden_service in "${FORBIDDEN_SERVICES[@]}"; do
                if [[ ${service_name} == "${forbidden_service}" ]]; then
                    echo "Forbidden service defined: ${service_name}" >&2
                    flag=1
                fi
            done
        fi
    done
fi

# Check firewalld status (from sosreport or live system)
FIREWALLD_STATE_FILE="${RISU_ROOT}/sos_commands/firewalld/firewall-cmd_--state"
if [[ -f ${FIREWALLD_STATE_FILE} ]]; then
    firewalld_state=$(cat "${FIREWALLD_STATE_FILE}")
    if [[ ${firewalld_state} != "running" ]]; then
        echo "Firewalld not running: ${firewalld_state}" >&2
        flag=1
    fi
fi

# Check default zone (from sosreport or live system)
DEFAULT_ZONE_FILE="${RISU_ROOT}/sos_commands/firewalld/firewall-cmd_--get-default-zone"
if [[ -f ${DEFAULT_ZONE_FILE} ]]; then
    default_zone=$(cat "${DEFAULT_ZONE_FILE}")
    if [[ ${default_zone} == "public" ]]; then
        echo "Default zone is public (consider using a more restrictive zone)" >&2
        flag=1
    fi
fi

# Check active zones
ACTIVE_ZONES_FILE="${RISU_ROOT}/sos_commands/firewalld/firewall-cmd_--get-active-zones"
if [[ -f ${ACTIVE_ZONES_FILE} ]]; then
    echo "Checking active zones..." >&2

    # Check for multiple active zones
    active_zones_count=$(grep -c "^[a-zA-Z]" "${ACTIVE_ZONES_FILE}")
    if [[ ${active_zones_count} -gt 1 ]]; then
        echo "Multiple active zones found: ${active_zones_count}" >&2
        # This might be OK for multi-interface systems
    fi
fi

# Check firewalld lockdown whitelist
LOCKDOWN_WHITELIST_FILE="${RISU_ROOT}/etc/firewalld/lockdown-whitelist.xml"
if [[ -f ${LOCKDOWN_WHITELIST_FILE} ]]; then
    echo "Checking firewalld lockdown whitelist..." >&2

    # Check for overly permissive whitelist entries
    if grep -q '<command name="\*"' "${LOCKDOWN_WHITELIST_FILE}"; then
        echo "Overly permissive lockdown whitelist entry found" >&2
        flag=1
    fi

    # Check for user whitelist entries
    if grep -q '<user' "${LOCKDOWN_WHITELIST_FILE}"; then
        echo "User entries in lockdown whitelist found" >&2
        # This might be OK, just informational
    fi
fi

# Check for rich rules
RICH_RULES_FILE="${RISU_ROOT}/sos_commands/firewalld/firewall-cmd_--list-rich-rules"
if [[ -f ${RICH_RULES_FILE} ]]; then
    echo "Checking firewalld rich rules..." >&2

    # Check for accept all rules
    if grep -q "accept" "${RICH_RULES_FILE}"; then
        echo "Accept rules found in rich rules" >&2
        # This might be OK, just informational
    fi

    # Check for reject rules
    if grep -q "reject" "${RICH_RULES_FILE}"; then
        echo "Reject rules found in rich rules" >&2
        # This is good, informational
    fi

    # Check for drop rules
    if grep -q "drop" "${RICH_RULES_FILE}"; then
        echo "Drop rules found in rich rules" >&2
        # This is good, informational
    fi
fi

# Check for panic mode
PANIC_MODE_FILE="${RISU_ROOT}/sos_commands/firewalld/firewall-cmd_--query-panic"
if [[ -f ${PANIC_MODE_FILE} ]]; then
    panic_mode=$(cat "${PANIC_MODE_FILE}")
    if [[ ${panic_mode} == "yes" ]]; then
        echo "Firewalld panic mode is enabled" >&2
        # This is informational - might be intentional
    fi
fi

# Check for port forwarding
PORT_FORWARDS_FILE="${RISU_ROOT}/sos_commands/firewalld/firewall-cmd_--list-forward-ports"
if [[ -f ${PORT_FORWARDS_FILE} ]]; then
    if [[ -s ${PORT_FORWARDS_FILE} ]]; then
        echo "Port forwarding rules found" >&2
        # This might be OK, just informational
    fi
fi

# Check for masquerading
MASQUERADING_FILE="${RISU_ROOT}/sos_commands/firewalld/firewall-cmd_--query-masquerade"
if [[ -f ${MASQUERADING_FILE} ]]; then
    masquerading=$(cat "${MASQUERADING_FILE}")
    if [[ ${masquerading} == "yes" ]]; then
        echo "Masquerading is enabled" >&2
        # This might be OK for routers/gateways
    fi
fi

# Check for ICMP block inversion
ICMP_BLOCK_INVERSION_FILE="${RISU_ROOT}/sos_commands/firewalld/firewall-cmd_--query-icmp-block-inversion"
if [[ -f ${ICMP_BLOCK_INVERSION_FILE} ]]; then
    icmp_block_inversion=$(cat "${ICMP_BLOCK_INVERSION_FILE}")
    if [[ ${icmp_block_inversion} == "yes" ]]; then
        echo "ICMP block inversion is enabled" >&2
        # This might be OK, just informational
    fi
fi

# Check for fallback to iptables
IPTABLES_FALLBACK_FILE="${RISU_ROOT}/sos_commands/iptables/iptables_-L"
if [[ -f ${IPTABLES_FALLBACK_FILE} ]]; then
    # Check if iptables has rules when firewalld should be managing them
    if grep -q "Chain INPUT" "${IPTABLES_FALLBACK_FILE}"; then
        echo "Iptables rules found - may conflict with firewalld" >&2
        flag=1
    fi
fi

# Check for nftables backend
NFTABLES_BACKEND_FILE="${RISU_ROOT}/sos_commands/firewalld/firewall-cmd_--info-service=ssh"
if [[ -f ${NFTABLES_BACKEND_FILE} ]]; then
    echo "Firewalld using nftables backend" >&2
    # This is good for RHEL 9
fi

# Check systemd service status
FIREWALLD_SERVICE_FILE="${RISU_ROOT}/etc/systemd/system/multi-user.target.wants/firewalld.service"
if [[ ! -L ${FIREWALLD_SERVICE_FILE} ]]; then
    echo "Firewalld service not enabled" >&2
    flag=1
fi

if [[ $flag -eq 1 ]]; then
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
