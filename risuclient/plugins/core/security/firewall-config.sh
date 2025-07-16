#!/bin/bash
# Copyright (C) 2024 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

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

# long_name: Firewall configuration validation
# description: Validates firewall configuration and checks for security issues
# priority: 820

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

flag=0

# Check firewall status and configuration
echo "Checking firewall configuration" >&2

# Check iptables
if [[ "x$RISU_LIVE" == "x1" ]]; then
    if command -v iptables >/dev/null 2>&1; then
        echo "iptables is available" >&2

        # Check if iptables has rules
        iptables_rules=$(iptables -L -n 2>/dev/null | grep -v "^Chain\|^target" | wc -l)
        if [[ $iptables_rules -gt 0 ]]; then
            echo "iptables has $iptables_rules rules configured" >&2
        else
            echo "iptables has no rules configured" >&2
        fi

        # Check default policies
        input_policy=$(iptables -L INPUT -n 2>/dev/null | head -1 | awk '{print $4}' | tr -d '()')
        forward_policy=$(iptables -L FORWARD -n 2>/dev/null | head -1 | awk '{print $4}' | tr -d '()')
        output_policy=$(iptables -L OUTPUT -n 2>/dev/null | head -1 | awk '{print $4}' | tr -d '()')

        echo "iptables INPUT policy: $input_policy" >&2
        echo "iptables FORWARD policy: $forward_policy" >&2
        echo "iptables OUTPUT policy: $output_policy" >&2

        # Check for overly permissive rules
        if iptables -L -n 2>/dev/null | grep -q "0.0.0.0/0.*ACCEPT"; then
            echo "iptables has overly permissive rules allowing all traffic" >&2
            flag=1
        fi

        # Check for logging rules
        if iptables -L -n 2>/dev/null | grep -q "LOG"; then
            echo "iptables has logging rules configured" >&2
        else
            echo "iptables has no logging rules configured" >&2
        fi
    else
        echo "iptables is not available" >&2
    fi
elif [[ "x$RISU_LIVE" == "x0" ]]; then
    # Check from sosreport
    if [[ -f "${RISU_ROOT}/sos_commands/networking/iptables_-L" ]]; then
        echo "iptables rules found in sosreport" >&2

        iptables_rules=$(grep -v "^Chain\|^target" "${RISU_ROOT}/sos_commands/networking/iptables_-L" | wc -l)
        if [[ $iptables_rules -gt 0 ]]; then
            echo "iptables had $iptables_rules rules configured" >&2
        else
            echo "iptables had no rules configured" >&2
        fi

        # Check for overly permissive rules
        if grep -q "0.0.0.0/0.*ACCEPT" "${RISU_ROOT}/sos_commands/networking/iptables_-L"; then
            echo "iptables had overly permissive rules allowing all traffic" >&2
            flag=1
        fi
    fi
fi

# Check firewalld
if [[ "x$RISU_LIVE" == "x1" ]]; then
    if command -v firewall-cmd >/dev/null 2>&1; then
        echo "firewalld is available" >&2

        if is_active firewalld; then
            echo "firewalld service is active" >&2

            # Check default zone
            default_zone=$(firewall-cmd --get-default-zone 2>/dev/null)
            if [[ -n $default_zone ]]; then
                echo "firewalld default zone: $default_zone" >&2
            fi

            # Check active zones
            active_zones=$(firewall-cmd --get-active-zones 2>/dev/null)
            if [[ -n $active_zones ]]; then
                echo "firewalld active zones: $active_zones" >&2
            fi

            # Check if public zone allows SSH
            if firewall-cmd --zone=public --query-service=ssh >/dev/null 2>&1; then
                echo "SSH is allowed in public zone" >&2
            else
                echo "SSH is not allowed in public zone" >&2
            fi

            # Check for overly permissive zones
            if firewall-cmd --list-all-zones 2>/dev/null | grep -q "target: ACCEPT"; then
                echo "firewalld has zones with ACCEPT target" >&2
            fi

            # Check for rich rules
            rich_rules=$(firewall-cmd --list-rich-rules 2>/dev/null | wc -l)
            if [[ $rich_rules -gt 0 ]]; then
                echo "firewalld has $rich_rules rich rules configured" >&2
            fi
        else
            echo "firewalld service is not active" >&2
        fi
    else
        echo "firewalld is not available" >&2
    fi
elif [[ "x$RISU_LIVE" == "x0" ]]; then
    # Check from sosreport
    if [[ -f "${RISU_ROOT}/sos_commands/networking/firewall-cmd_--list-all-zones" ]]; then
        echo "firewalld configuration found in sosreport" >&2

        # Check for overly permissive zones
        if grep -q "target: ACCEPT" "${RISU_ROOT}/sos_commands/networking/firewall-cmd_--list-all-zones"; then
            echo "firewalld had zones with ACCEPT target" >&2
        fi
    fi
fi

# Check ufw (Ubuntu Firewall)
if [[ "x$RISU_LIVE" == "x1" ]]; then
    if command -v ufw >/dev/null 2>&1; then
        echo "ufw is available" >&2

        ufw_status=$(ufw status 2>/dev/null | head -1)
        echo "ufw status: $ufw_status" >&2

        if [[ $ufw_status == *"inactive"* ]]; then
            echo "ufw is inactive" >&2
        else
            # Check ufw rules
            ufw_rules=$(ufw status numbered 2>/dev/null | grep -v "Status:\|-----\|^$" | wc -l)
            if [[ $ufw_rules -gt 0 ]]; then
                echo "ufw has $ufw_rules rules configured" >&2
            fi

            # Check default policies
            ufw_defaults=$(ufw status verbose 2>/dev/null | grep "Default:")
            if [[ -n $ufw_defaults ]]; then
                echo "ufw defaults: $ufw_defaults" >&2
            fi
        fi
    else
        echo "ufw is not available" >&2
    fi
elif [[ "x$RISU_LIVE" == "x0" ]]; then
    # Check from sosreport
    if [[ -f "${RISU_ROOT}/sos_commands/networking/ufw_status" ]]; then
        echo "ufw configuration found in sosreport" >&2

        ufw_status=$(head -1 "${RISU_ROOT}/sos_commands/networking/ufw_status")
        echo "ufw status was: $ufw_status" >&2
    fi
fi

# Check for common firewall misconfigurations
echo "Checking for common firewall misconfigurations" >&2

# Check if both iptables and firewalld are running
if [[ "x$RISU_LIVE" == "x1" ]]; then
    if is_active iptables && is_active firewalld; then
        echo "Both iptables and firewalld services are active - potential conflict" >&2
        flag=1
    fi
fi

# Check for fail2ban
if [[ "x$RISU_LIVE" == "x1" ]]; then
    if command -v fail2ban-client >/dev/null 2>&1; then
        echo "fail2ban is available" >&2

        if is_active fail2ban; then
            echo "fail2ban service is active" >&2

            # Check fail2ban status
            fail2ban_status=$(fail2ban-client status 2>/dev/null)
            if [[ -n $fail2ban_status ]]; then
                echo "fail2ban jails: $fail2ban_status" >&2
            fi
        else
            echo "fail2ban service is not active" >&2
        fi
    else
        echo "fail2ban is not available" >&2
    fi
elif [[ "x$RISU_LIVE" == "x0" ]]; then
    # Check from sosreport
    if [[ -f "${RISU_ROOT}/sos_commands/security/fail2ban-client_status" ]]; then
        echo "fail2ban configuration found in sosreport" >&2

        fail2ban_status=$(cat "${RISU_ROOT}/sos_commands/security/fail2ban-client_status")
        echo "fail2ban jails were: $fail2ban_status" >&2
    fi
fi

# Check network interfaces for firewall binding
if [[ "x$RISU_LIVE" == "x1" ]]; then
    interfaces=$(ip link show 2>/dev/null | grep "^[0-9]:" | awk '{print $2}' | tr -d ':')
    for interface in $interfaces; do
        if [[ $interface != "lo" ]]; then
            echo "Network interface found: $interface" >&2
        fi
    done
elif [[ "x$RISU_LIVE" == "x0" ]]; then
    if [[ -f "${RISU_ROOT}/sos_commands/networking/ip_link_show" ]]; then
        interfaces=$(grep "^[0-9]:" "${RISU_ROOT}/sos_commands/networking/ip_link_show" | awk '{print $2}' | tr -d ':')
        for interface in $interfaces; do
            if [[ $interface != "lo" ]]; then
                echo "Network interface was: $interface" >&2
            fi
        done
    fi
fi

# Check for open ports
if [[ "x$RISU_LIVE" == "x1" ]]; then
    if command -v netstat >/dev/null 2>&1; then
        listening_ports=$(netstat -tlnp 2>/dev/null | grep "LISTEN" | wc -l)
        if [[ $listening_ports -gt 0 ]]; then
            echo "Found $listening_ports listening ports" >&2

            # Check for potentially dangerous open ports
            if netstat -tlnp 2>/dev/null | grep -q ":23\|:telnet"; then
                echo "Telnet port (23) is open" >&2
                flag=1
            fi

            if netstat -tlnp 2>/dev/null | grep -q ":21\|:ftp"; then
                echo "FTP port (21) is open" >&2
                flag=1
            fi

            if netstat -tlnp 2>/dev/null | grep -q ":80.*LISTEN"; then
                echo "HTTP port (80) is open" >&2
            fi

            if netstat -tlnp 2>/dev/null | grep -q ":443.*LISTEN"; then
                echo "HTTPS port (443) is open" >&2
            fi
        fi
    fi
elif [[ "x$RISU_LIVE" == "x0" ]]; then
    if [[ -f "${RISU_ROOT}/sos_commands/networking/netstat_-tlnp" ]]; then
        listening_ports=$(grep "LISTEN" "${RISU_ROOT}/sos_commands/networking/netstat_-tlnp" | wc -l)
        if [[ $listening_ports -gt 0 ]]; then
            echo "Found $listening_ports listening ports" >&2

            # Check for potentially dangerous open ports
            if grep -q ":23\|:telnet" "${RISU_ROOT}/sos_commands/networking/netstat_-tlnp"; then
                echo "Telnet port (23) was open" >&2
                flag=1
            fi

            if grep -q ":21\|:ftp" "${RISU_ROOT}/sos_commands/networking/netstat_-tlnp"; then
                echo "FTP port (21) was open" >&2
                flag=1
            fi
        fi
    fi
fi

if [[ $flag == "1" ]]; then
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
