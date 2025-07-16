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

# long_name: Validate kernel security parameters for RHEL 9
# description: Validate sysctl kernel security parameters for CCN-STIC-610A22
# priority: 130
# bugzilla: https://www.ccn-cert.cni.es/pdf/guias/series-ccn-stic/guias-de-acceso-publico-ccn-stic/6768-ccn-stic-610a22-perfilado-de-seguridad-red-hat-enterprise-linux-9-0/file.html

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

# Array of sysctl parameters to check with their expected values
declare -A SYSCTL_PARAMS=(
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
    ["net.ipv6.conf.all.disable_ipv6"]="1"
    ["net.ipv6.conf.default.disable_ipv6"]="1"
    ["net.ipv6.conf.lo.disable_ipv6"]="1"
    ["net.ipv6.conf.all.forwarding"]="0"
    ["net.ipv6.conf.default.forwarding"]="0"
    ["net.ipv6.conf.all.accept_dad"]="0"
    ["net.ipv6.conf.default.accept_dad"]="0"
    ["net.ipv6.conf.all.accept_ra"]="0"
    ["net.ipv6.conf.default.accept_ra"]="0"
    ["net.ipv6.conf.all.accept_ra_defrtr"]="0"
    ["net.ipv6.conf.default.accept_ra_defrtr"]="0"
    ["net.ipv6.conf.all.accept_ra_pinfo"]="0"
    ["net.ipv6.conf.default.accept_ra_pinfo"]="0"
    ["net.ipv6.conf.all.accept_ra_rtr_pref"]="0"
    ["net.ipv6.conf.default.accept_ra_rtr_pref"]="0"
    ["net.ipv6.conf.all.autoconf"]="0"
    ["net.ipv6.conf.default.autoconf"]="0"
    ["net.ipv6.conf.all.dad_transmits"]="0"
    ["net.ipv6.conf.default.dad_transmits"]="0"
    ["net.ipv6.conf.all.max_addresses"]="1"
    ["net.ipv6.conf.default.max_addresses"]="1"
    ["net.ipv6.conf.all.router_solicitations"]="0"
    ["net.ipv6.conf.default.router_solicitations"]="0"
    ["kernel.randomize_va_space"]="2"
    ["fs.suid_dumpable"]="0"
    ["kernel.dmesg_restrict"]="1"
    ["kernel.kptr_restrict"]="1"
    ["kernel.yama.ptrace_scope"]="1"
    ["net.core.bpf_jit_enable"]="0"
    ["net.core.bpf_jit_harden"]="2"
    ["vm.mmap_rnd_bits"]="32"
    ["vm.mmap_rnd_compat_bits"]="16"
    ["user.max_user_namespaces"]="0"
    ["kernel.unprivileged_userns_clone"]="0"
    ["kernel.unprivileged_bpf_disabled"]="1"
    ["net.ipv4.tcp_rfc1337"]="1"
    ["net.ipv4.tcp_timestamps"]="0"
    ["net.ipv4.tcp_fastopen"]="0"
    ["net.ipv4.tcp_congestion_control"]="bbr"
    ["net.core.default_qdisc"]="fq"
    ["net.ipv4.tcp_slow_start_after_idle"]="0"
    ["net.ipv4.tcp_window_scaling"]="1"
    ["net.ipv4.tcp_sack"]="1"
    ["net.ipv4.tcp_fack"]="1"
    ["net.ipv4.tcp_ecn"]="2"
    ["net.ipv4.tcp_dsack"]="1"
    ["net.ipv4.tcp_low_latency"]="1"
    ["net.ipv4.tcp_adv_win_scale"]="1"
    ["net.ipv4.tcp_moderate_rcvbuf"]="1"
    ["net.ipv4.tcp_rmem"]="4096 87380 6291456"
    ["net.ipv4.tcp_wmem"]="4096 16384 4194304"
    ["net.core.rmem_default"]="31457280"
    ["net.core.rmem_max"]="134217728"
    ["net.core.wmem_default"]="31457280"
    ["net.core.wmem_max"]="134217728"
    ["net.core.netdev_max_backlog"]="5000"
    ["net.core.netdev_budget"]="600"
    ["net.ipv4.tcp_mtu_probing"]="1"
)

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

echo "Checking RHEL 9 kernel security parameters..." >&2

# Check each required parameter
for param in "${!SYSCTL_PARAMS[@]}"; do
    required_value="${SYSCTL_PARAMS[$param]}"
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

# Check for RHEL 9 specific security features
echo "Checking RHEL 9 specific security features..." >&2

# Check for kernel lockdown
KERNEL_LOCKDOWN_FILE="${RISU_ROOT}/sys/kernel/security/lockdown"
if [[ -f ${KERNEL_LOCKDOWN_FILE} ]]; then
    lockdown_mode=$(cat "${KERNEL_LOCKDOWN_FILE}")
    if [[ ${lockdown_mode} != *"[integrity]"* && ${lockdown_mode} != *"[confidentiality]"* ]]; then
        echo "Kernel lockdown not enabled properly: ${lockdown_mode}" >&2
        flag=1
    fi
fi

# Check for FIPS mode
FIPS_MODE_FILE="${RISU_ROOT}/proc/sys/crypto/fips_enabled"
if [[ -f ${FIPS_MODE_FILE} ]]; then
    fips_enabled=$(cat "${FIPS_MODE_FILE}")
    if [[ ${fips_enabled} != "1" ]]; then
        echo "FIPS mode not enabled: ${fips_enabled}" >&2
        flag=1
    fi
fi

# Check for KPTI (Kernel Page Table Isolation)
KPTI_STATUS_FILE="${RISU_ROOT}/sys/devices/system/cpu/vulnerabilities/meltdown"
if [[ -f ${KPTI_STATUS_FILE} ]]; then
    kpti_status=$(cat "${KPTI_STATUS_FILE}")
    if [[ ${kpti_status} == *"Vulnerable"* ]]; then
        echo "KPTI (Kernel Page Table Isolation) not enabled: ${kpti_status}" >&2
        flag=1
    fi
fi

# Check for SMEP (Supervisor Mode Execution Prevention)
SMEP_STATUS_FILE="${RISU_ROOT}/proc/cpuinfo"
if [[ -f ${SMEP_STATUS_FILE} ]]; then
    if ! grep -q "smep" "${SMEP_STATUS_FILE}"; then
        echo "SMEP (Supervisor Mode Execution Prevention) not available or enabled" >&2
        flag=1
    fi
fi

# Check for SMAP (Supervisor Mode Access Prevention)
if [[ -f ${SMEP_STATUS_FILE} ]]; then
    if ! grep -q "smap" "${SMEP_STATUS_FILE}"; then
        echo "SMAP (Supervisor Mode Access Prevention) not available or enabled" >&2
        flag=1
    fi
fi

# Check for Control Flow Integrity
CFI_STATUS_FILE="${RISU_ROOT}/proc/cpuinfo"
if [[ -f ${CFI_STATUS_FILE} ]]; then
    if ! grep -q "cfi" "${CFI_STATUS_FILE}"; then
        echo "Control Flow Integrity not available" >&2
        # This is informational, not necessarily a failure for older hardware
    fi
fi

# Check for dangerous parameters that should not be set
declare -A FORBIDDEN_PARAMS=(
    ["kernel.core_pattern"]="*|*"
    ["kernel.modprobe"]="*"
    ["vm.unprivileged_userfaultfd"]="1"
)

for param in "${!FORBIDDEN_PARAMS[@]}"; do
    config_value=$(get_sysctl_value "$param")
    forbidden_pattern="${FORBIDDEN_PARAMS[$param]}"

    if [[ -n $config_value ]]; then
        case "$forbidden_pattern" in
        "*|*")
            # Should not contain pipe (|) which allows external programs
            if [[ $config_value == *"|"* ]]; then
                echo "Dangerous kernel parameter: ${param}=${config_value} (allows external programs)" >&2
                flag=1
            fi
            ;;
        "*")
            # Should not be set at all
            echo "Dangerous kernel parameter should not be set: ${param}=${config_value}" >&2
            flag=1
            ;;
        "1")
            # Should not be 1
            if [[ $config_value == "1" ]]; then
                echo "Dangerous kernel parameter: ${param}=${config_value}" >&2
                flag=1
            fi
            ;;
        esac
    fi
done

# Check for systemd-specific security settings
SYSTEMD_SYSTEM_CONF="${RISU_ROOT}/etc/systemd/system.conf"
if [[ -f ${SYSTEMD_SYSTEM_CONF} ]]; then
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
fi

if [[ $flag -eq 1 ]]; then
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
