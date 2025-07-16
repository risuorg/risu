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

# long_name: CIS benchmark security validation
# description: Validates basic CIS benchmark security settings
# priority: 810

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

flag=0

# Check filesystem configuration
if [[ "x$RISU_LIVE" == "x1" ]]; then
    fstab_file="/etc/fstab"
    mount_output=$(mount)
elif [[ "x$RISU_LIVE" == "x0" ]]; then
    fstab_file="${RISU_ROOT}/etc/fstab"
    mount_output=$(cat "${RISU_ROOT}/proc/mounts" 2>/dev/null)
fi

if [[ -f $fstab_file ]]; then
    echo "Checking filesystem security settings" >&2

    # Check /tmp partition
    if grep -q "/tmp" "$fstab_file"; then
        echo "Separate /tmp partition configured" >&2

        # Check /tmp mount options
        if grep "/tmp" "$fstab_file" | grep -q "noexec"; then
            echo "/tmp mounted with noexec option" >&2
        else
            echo "/tmp not mounted with noexec option" >&2
            flag=1
        fi

        if grep "/tmp" "$fstab_file" | grep -q "nosuid"; then
            echo "/tmp mounted with nosuid option" >&2
        else
            echo "/tmp not mounted with nosuid option" >&2
            flag=1
        fi

        if grep "/tmp" "$fstab_file" | grep -q "nodev"; then
            echo "/tmp mounted with nodev option" >&2
        else
            echo "/tmp not mounted with nodev option" >&2
            flag=1
        fi
    else
        echo "No separate /tmp partition configured" >&2
    fi

    # Check /var partition
    if grep -q "/var" "$fstab_file"; then
        echo "Separate /var partition configured" >&2
    else
        echo "No separate /var partition configured" >&2
    fi

    # Check /var/log partition
    if grep -q "/var/log" "$fstab_file"; then
        echo "Separate /var/log partition configured" >&2
    else
        echo "No separate /var/log partition configured" >&2
    fi

    # Check /home partition
    if grep -q "/home" "$fstab_file"; then
        echo "Separate /home partition configured" >&2

        # Check /home mount options
        if grep "/home" "$fstab_file" | grep -q "nodev"; then
            echo "/home mounted with nodev option" >&2
        else
            echo "/home not mounted with nodev option" >&2
            flag=1
        fi
    else
        echo "No separate /home partition configured" >&2
    fi
fi

# Check network parameters
if [[ "x$RISU_LIVE" == "x1" ]]; then
    sysctl_conf="/etc/sysctl.conf"
    sysctl_dir="/etc/sysctl.d"
elif [[ "x$RISU_LIVE" == "x0" ]]; then
    sysctl_conf="${RISU_ROOT}/etc/sysctl.conf"
    sysctl_dir="${RISU_ROOT}/etc/sysctl.d"
fi

echo "Checking network security parameters" >&2

# Check IP forwarding
if [[ "x$RISU_LIVE" == "x1" ]]; then
    ip_forward=$(sysctl -n net.ipv4.ip_forward 2>/dev/null)
else
    ip_forward=$(grep "net.ipv4.ip_forward" "$sysctl_conf" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
fi

if [[ $ip_forward == "0" ]]; then
    echo "IP forwarding disabled" >&2
else
    echo "IP forwarding enabled" >&2
fi

# Check send redirects
if [[ "x$RISU_LIVE" == "x1" ]]; then
    send_redirects=$(sysctl -n net.ipv4.conf.all.send_redirects 2>/dev/null)
else
    send_redirects=$(grep "net.ipv4.conf.all.send_redirects" "$sysctl_conf" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
fi

if [[ $send_redirects == "0" ]]; then
    echo "Send redirects disabled" >&2
else
    echo "Send redirects enabled" >&2
    flag=1
fi

# Check source routed packets
if [[ "x$RISU_LIVE" == "x1" ]]; then
    accept_source_route=$(sysctl -n net.ipv4.conf.all.accept_source_route 2>/dev/null)
else
    accept_source_route=$(grep "net.ipv4.conf.all.accept_source_route" "$sysctl_conf" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
fi

if [[ $accept_source_route == "0" ]]; then
    echo "Source routed packets disabled" >&2
else
    echo "Source routed packets enabled" >&2
    flag=1
fi

# Check ICMP redirects
if [[ "x$RISU_LIVE" == "x1" ]]; then
    accept_redirects=$(sysctl -n net.ipv4.conf.all.accept_redirects 2>/dev/null)
else
    accept_redirects=$(grep "net.ipv4.conf.all.accept_redirects" "$sysctl_conf" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
fi

if [[ $accept_redirects == "0" ]]; then
    echo "ICMP redirects disabled" >&2
else
    echo "ICMP redirects enabled" >&2
    flag=1
fi

# Check log martians
if [[ "x$RISU_LIVE" == "x1" ]]; then
    log_martians=$(sysctl -n net.ipv4.conf.all.log_martians 2>/dev/null)
else
    log_martians=$(grep "net.ipv4.conf.all.log_martians" "$sysctl_conf" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
fi

if [[ $log_martians == "1" ]]; then
    echo "Log martians enabled" >&2
else
    echo "Log martians disabled" >&2
fi

# Check password policies
if [[ "x$RISU_LIVE" == "x1" ]]; then
    login_defs="/etc/login.defs"
    pwquality_conf="/etc/security/pwquality.conf"
elif [[ "x$RISU_LIVE" == "x0" ]]; then
    login_defs="${RISU_ROOT}/etc/login.defs"
    pwquality_conf="${RISU_ROOT}/etc/security/pwquality.conf"
fi

echo "Checking password policies" >&2

if [[ -f $login_defs ]]; then
    # Check password aging
    pass_max_days=$(grep "^PASS_MAX_DAYS" "$login_defs" | awk '{print $2}')
    if [[ -n $pass_max_days && $pass_max_days -le 90 ]]; then
        echo "Password max days set to: $pass_max_days" >&2
    else
        echo "Password max days not properly configured" >&2
        flag=1
    fi

    pass_min_days=$(grep "^PASS_MIN_DAYS" "$login_defs" | awk '{print $2}')
    if [[ -n $pass_min_days && $pass_min_days -ge 1 ]]; then
        echo "Password min days set to: $pass_min_days" >&2
    else
        echo "Password min days not properly configured" >&2
        flag=1
    fi

    pass_warn_age=$(grep "^PASS_WARN_AGE" "$login_defs" | awk '{print $2}')
    if [[ -n $pass_warn_age && $pass_warn_age -ge 7 ]]; then
        echo "Password warn age set to: $pass_warn_age" >&2
    else
        echo "Password warn age not properly configured" >&2
        flag=1
    fi
fi

# Check SSH configuration
if [[ "x$RISU_LIVE" == "x1" ]]; then
    sshd_config="/etc/ssh/sshd_config"
elif [[ "x$RISU_LIVE" == "x0" ]]; then
    sshd_config="${RISU_ROOT}/etc/ssh/sshd_config"
fi

if [[ -f $sshd_config ]]; then
    echo "Checking SSH security configuration" >&2

    # Check root login
    if grep -q "^PermitRootLogin no" "$sshd_config"; then
        echo "Root login disabled" >&2
    else
        echo "Root login not disabled" >&2
        flag=1
    fi

    # Check empty passwords
    if grep -q "^PermitEmptyPasswords no" "$sshd_config"; then
        echo "Empty passwords disabled" >&2
    else
        echo "Empty passwords not disabled" >&2
        flag=1
    fi

    # Check protocol version
    if grep -q "^Protocol 2" "$sshd_config"; then
        echo "SSH protocol 2 configured" >&2
    else
        echo "SSH protocol 2 not explicitly configured" >&2
    fi

    # Check X11 forwarding
    if grep -q "^X11Forwarding no" "$sshd_config"; then
        echo "X11 forwarding disabled" >&2
    else
        echo "X11 forwarding not disabled" >&2
    fi

    # Check max auth tries
    max_auth_tries=$(grep "^MaxAuthTries" "$sshd_config" | awk '{print $2}')
    if [[ -n $max_auth_tries && $max_auth_tries -le 4 ]]; then
        echo "Max auth tries set to: $max_auth_tries" >&2
    else
        echo "Max auth tries not properly configured" >&2
        flag=1
    fi
fi

# Check audit system
if [[ "x$RISU_LIVE" == "x1" ]]; then
    if is_active auditd; then
        echo "Audit daemon is active" >&2
    else
        echo "Audit daemon is not active" >&2
        flag=1
    fi
elif [[ "x$RISU_LIVE" == "x0" ]]; then
    if [[ -f "${RISU_ROOT}/etc/audit/auditd.conf" ]]; then
        echo "Audit system configuration found" >&2
    else
        echo "Audit system not configured" >&2
        flag=1
    fi
fi

# Check cron restrictions
if [[ "x$RISU_LIVE" == "x1" ]]; then
    cron_allow="/etc/cron.allow"
    cron_deny="/etc/cron.deny"
elif [[ "x$RISU_LIVE" == "x0" ]]; then
    cron_allow="${RISU_ROOT}/etc/cron.allow"
    cron_deny="${RISU_ROOT}/etc/cron.deny"
fi

echo "Checking cron restrictions" >&2

if [[ -f $cron_allow ]]; then
    echo "Cron allow file exists" >&2
elif [[ -f $cron_deny ]]; then
    echo "Cron deny file exists" >&2
else
    echo "No cron access restrictions configured" >&2
    flag=1
fi

if [[ $flag == "1" ]]; then
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
