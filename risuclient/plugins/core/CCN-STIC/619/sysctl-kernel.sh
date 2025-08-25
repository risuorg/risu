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

# long_name: Validate kernel security parameters
# description: Validate sysctl kernel security parameters for CCN-STIC-619
# priority: 910
# bugzilla: https://www.ccn-cert.cni.es/pdf/guias/series-ccn-stic/guias-de-acceso-publico-ccn-stic/3674-ccn-stic-619-implementacion-de-seguridad-sobre-centos7/file.html

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

# Define required kernel security parameters
declare -A REQUIRED_PARAMS=(
    ["kernel.dmesg_restrict"]="1"
    ["kernel.kptr_restrict"]="2"
    ["kernel.yama.ptrace_scope"]="1"
    ["kernel.kexec_load_disabled"]="1"
    ["kernel.unprivileged_bpf_disabled"]="1"
    ["net.core.bpf_jit_harden"]="2"
    ["net.ipv4.ip_forward"]="0"
    ["net.ipv4.conf.all.send_redirects"]="0"
    ["net.ipv4.conf.default.send_redirects"]="0"
    ["net.ipv4.conf.all.accept_redirects"]="0"
    ["net.ipv4.conf.default.accept_redirects"]="0"
    ["net.ipv4.conf.all.secure_redirects"]="0"
    ["net.ipv4.conf.default.secure_redirects"]="0"
    ["net.ipv4.conf.all.accept_source_route"]="0"
    ["net.ipv4.conf.default.accept_source_route"]="0"
    ["net.ipv4.conf.all.log_martians"]="1"
    ["net.ipv4.conf.default.log_martians"]="1"
    ["net.ipv4.icmp_echo_ignore_broadcasts"]="1"
    ["net.ipv4.icmp_ignore_bogus_error_responses"]="1"
    ["net.ipv4.tcp_syncookies"]="1"
    ["net.ipv4.conf.all.rp_filter"]="1"
    ["net.ipv4.conf.default.rp_filter"]="1"
    ["net.ipv6.conf.all.accept_redirects"]="0"
    ["net.ipv6.conf.default.accept_redirects"]="0"
    ["net.ipv6.conf.all.accept_source_route"]="0"
    ["net.ipv6.conf.default.accept_source_route"]="0"
    ["net.ipv6.conf.all.accept_ra"]="0"
    ["net.ipv6.conf.default.accept_ra"]="0"
    ["fs.suid_dumpable"]="0"
    ["fs.protected_hardlinks"]="1"
    ["fs.protected_symlinks"]="1"
)

flag=0

# Check sysctl configuration file
SYSCTL_CONF="${RISU_ROOT}/etc/sysctl.conf"
SYSCTL_D_DIR="${RISU_ROOT}/etc/sysctl.d"

# Function is now available in common functions

# Function to get live system value
get_live_value() {
    local param="$1"
    if [[ ${RISU_LIVE} == "1" ]]; then
        sysctl -n "${param}" 2>/dev/null
    else
        # Try to get from proc filesystem in sosreport
        local proc_path="${RISU_ROOT}/proc/sys/${param//./\/}"
        if [[ -f ${proc_path} ]]; then
            cat "${proc_path}" 2>/dev/null
        fi
    fi
}

echo "Checking kernel security parameters..." >&2

# Check each required parameter
for param in "${!REQUIRED_PARAMS[@]}"; do
    required_value="${REQUIRED_PARAMS[$param]}"
    config_value=$(get_sysctl_value "$param")
    live_value=$(get_live_value "$param")

    # Check if parameter is configured
    if [[ -z $config_value ]]; then
        echo "Missing kernel parameter: ${param} (should be ${required_value})" >&2
        flag=1
        continue
    fi

    # Check if configured value matches required value
    if [[ $config_value != "$required_value" ]]; then
        echo "Incorrect kernel parameter: ${param}=${config_value} (should be ${required_value})" >&2
        flag=1
    fi

    # Check if live value matches configured value (if available)
    if [[ -n $live_value && $live_value != "$config_value" ]]; then
        echo "Runtime kernel parameter mismatch: ${param}=${live_value} (configured: ${config_value})" >&2
        flag=1
    fi
done

# Check for dangerous parameters that should not be set
declare -A FORBIDDEN_PARAMS=(
    ["kernel.core_pattern"]="core"
    ["kernel.core_uses_pid"]="1"
)

for param in "${!FORBIDDEN_PARAMS[@]}"; do
    config_value=$(get_sysctl_value "$param")
    if [[ -n $config_value ]]; then
        case "$param" in
        "kernel.core_pattern")
            # Should not contain pipe (|) which allows external programs
            if [[ $config_value == *"|"* ]]; then
                echo "Dangerous kernel parameter: ${param}=${config_value} (allows external programs)" >&2
                flag=1
            fi
            ;;
        esac
    fi
done

if [[ $flag -eq 1 ]]; then
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
