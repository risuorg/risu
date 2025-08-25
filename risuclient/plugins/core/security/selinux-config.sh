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

# long_name: SELinux configuration validation
# description: Validates SELinux configuration and checks for security issues
# priority: 810

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

flag=0

# Check if SELinux is available
if [[ "x$RISU_LIVE" == "x1" ]]; then
    selinux_config="/etc/selinux/config"
    selinux_status_file="/sys/fs/selinux/enforce"
elif [[ "x$RISU_LIVE" == "x0" ]]; then
    selinux_config="${RISU_ROOT}/etc/selinux/config"
    selinux_status_file="${RISU_ROOT}/sys/fs/selinux/enforce"
fi

if [[ ! -f $selinux_config ]]; then
    echo "SELinux configuration not found" >&2
    exit ${RC_SKIPPED}
fi

echo "Checking SELinux configuration" >&2

# Check SELinux state
selinux_state=$(grep "^SELINUX=" "$selinux_config" | cut -d'=' -f2)
echo "SELinux state configured: $selinux_state" >&2

case "$selinux_state" in
"enforcing")
    echo "SELinux is configured in enforcing mode" >&2
    ;;
"permissive")
    echo "SELinux is configured in permissive mode" >&2
    ;;
"disabled")
    echo "SELinux is disabled" >&2
    flag=1
    ;;
*)
    echo "SELinux state is unknown: $selinux_state" >&2
    flag=1
    ;;
esac

# Check SELinux policy type
selinux_policy=$(grep "^SELINUXTYPE=" "$selinux_config" | cut -d'=' -f2)
if [[ -n $selinux_policy ]]; then
    echo "SELinux policy type: $selinux_policy" >&2

    case "$selinux_policy" in
    "targeted")
        echo "Using targeted SELinux policy" >&2
        ;;
    "strict")
        echo "Using strict SELinux policy" >&2
        ;;
    "mls")
        echo "Using MLS SELinux policy" >&2
        ;;
    *)
        echo "Unknown SELinux policy type: $selinux_policy" >&2
        ;;
    esac
else
    echo "SELinux policy type not configured" >&2
    flag=1
fi

# Check current SELinux status on live systems
if [[ "x$RISU_LIVE" == "x1" ]]; then
    if command -v sestatus >/dev/null 2>&1; then
        current_status=$(sestatus | grep "SELinux status:" | awk '{print $3}')
        echo "Current SELinux status: $current_status" >&2

        if [[ $current_status != "enabled" ]]; then
            echo "SELinux is not currently enabled" >&2
            flag=1
        fi

        current_mode=$(sestatus | grep "Current mode:" | awk '{print $3}')
        echo "Current SELinux mode: $current_mode" >&2

        if [[ $current_mode == "permissive" ]]; then
            echo "SELinux is in permissive mode" >&2
        elif [[ $current_mode == "enforcing" ]]; then
            echo "SELinux is in enforcing mode" >&2
        fi

        # Check if SELinux is temporarily disabled
        if [[ -f $selinux_status_file ]]; then
            enforce_status=$(cat "$selinux_status_file" 2>/dev/null)
            if [[ $enforce_status == "0" ]]; then
                echo "SELinux enforcement is temporarily disabled" >&2
            fi
        fi
    else
        echo "SELinux tools not available" >&2
    fi
elif [[ "x$RISU_LIVE" == "x0" ]]; then
    # Check from sosreport
    if [[ -f $selinux_status_file ]]; then
        enforce_status=$(cat "$selinux_status_file" 2>/dev/null)
        if [[ $enforce_status == "1" ]]; then
            echo "SELinux was in enforcing mode" >&2
        elif [[ $enforce_status == "0" ]]; then
            echo "SELinux was in permissive mode" >&2
        fi
    fi
fi

# Check for SELinux policy modules
if [[ "x$RISU_LIVE" == "x1" ]]; then
    semodule_dir="/etc/selinux/targeted/modules"
elif [[ "x$RISU_LIVE" == "x0" ]]; then
    semodule_dir="${RISU_ROOT}/etc/selinux/targeted/modules"
fi

if [[ -d $semodule_dir ]]; then
    echo "SELinux policy modules directory found" >&2

    # Count policy modules
    if [[ "x$RISU_LIVE" == "x1" ]]; then
        if command -v semodule >/dev/null 2>&1; then
            module_count=$(semodule -l | wc -l)
            echo "Number of SELinux policy modules: $module_count" >&2
        fi
    fi
fi

# Check for SELinux denials
if [[ "x$RISU_LIVE" == "x1" ]]; then
    # Check recent denials in audit log
    if [[ -f "/var/log/audit/audit.log" ]]; then
        recent_denials=$(grep "avc.*denied" /var/log/audit/audit.log | tail -10 | wc -l)
        if [[ $recent_denials -gt 0 ]]; then
            echo "Recent SELinux denials found in audit log: $recent_denials" >&2
        fi
    fi

    # Check for denials in messages log
    if [[ -f "/var/log/messages" ]]; then
        recent_denials=$(grep "avc.*denied" /var/log/messages | tail -10 | wc -l)
        if [[ $recent_denials -gt 0 ]]; then
            echo "Recent SELinux denials found in messages log: $recent_denials" >&2
        fi
    fi
elif [[ "x$RISU_LIVE" == "x0" ]]; then
    # Check from sosreport
    if [[ -f "${RISU_ROOT}/var/log/audit/audit.log" ]]; then
        recent_denials=$(grep "avc.*denied" "${RISU_ROOT}/var/log/audit/audit.log" | tail -10 | wc -l)
        if [[ $recent_denials -gt 0 ]]; then
            echo "SELinux denials found in audit log: $recent_denials" >&2
        fi
    fi

    if [[ -f "${RISU_ROOT}/var/log/messages" ]]; then
        recent_denials=$(grep "avc.*denied" "${RISU_ROOT}/var/log/messages" | tail -10 | wc -l)
        if [[ $recent_denials -gt 0 ]]; then
            echo "SELinux denials found in messages log: $recent_denials" >&2
        fi
    fi
fi

# Check SELinux file contexts
if [[ "x$RISU_LIVE" == "x1" ]]; then
    file_contexts="/etc/selinux/targeted/contexts/files/file_contexts"
elif [[ "x$RISU_LIVE" == "x0" ]]; then
    file_contexts="${RISU_ROOT}/etc/selinux/targeted/contexts/files/file_contexts"
fi

if [[ -f $file_contexts ]]; then
    echo "SELinux file contexts configuration found" >&2

    # Check file contexts size
    context_count=$(wc -l <"$file_contexts" 2>/dev/null)
    if [[ -n $context_count ]]; then
        echo "Number of file context rules: $context_count" >&2
    fi
fi

# Check for custom SELinux policies
if [[ "x$RISU_LIVE" == "x1" ]]; then
    local_policy_dir="/etc/selinux/targeted/contexts/users"
elif [[ "x$RISU_LIVE" == "x0" ]]; then
    local_policy_dir="${RISU_ROOT}/etc/selinux/targeted/contexts/users"
fi

if [[ -d $local_policy_dir ]]; then
    echo "SELinux user contexts directory found" >&2
fi

# Check SELinux boolean settings
if [[ "x$RISU_LIVE" == "x1" ]]; then
    if command -v getsebool >/dev/null 2>&1; then
        # Check some common security-relevant booleans
        booleans=(
            "httpd_can_network_connect"
            "httpd_can_network_connect_db"
            "httpd_unified"
            "samba_enable_home_dirs"
            "use_nfs_home_dirs"
            "allow_execmem"
            "allow_execstack"
        )

        for boolean in "${booleans[@]}"; do
            bool_status=$(getsebool "$boolean" 2>/dev/null)
            if [[ -n $bool_status ]]; then
                echo "SELinux boolean $boolean: $bool_status" >&2

                if [[ $bool_status == *"on"* ]]; then
                    case "$boolean" in
                    "allow_execmem" | "allow_execstack")
                        echo "Security-sensitive boolean $boolean is enabled" >&2
                        ;;
                    esac
                fi
            fi
        done
    fi
fi

# Check for SELinux troubleshooting tools
if [[ "x$RISU_LIVE" == "x1" ]]; then
    if command -v sealert >/dev/null 2>&1; then
        echo "SELinux troubleshooting tools available" >&2
    else
        echo "SELinux troubleshooting tools not available" >&2
    fi
fi

# Check for setroubleshoot service
if [[ "x$RISU_LIVE" == "x1" ]]; then
    if is_active setroubleshoot; then
        echo "Setroubleshoot service is active" >&2
    else
        echo "Setroubleshoot service is not active" >&2
    fi
fi

if [[ $flag == "1" ]]; then
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
