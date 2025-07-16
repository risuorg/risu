#!/bin/bash

# Copyright (C) 2024 Pablo Iranzo Gómez (Pablo.Iranzo@gmail.com)

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

# long_name: OpenShift Pod Restart Patterns Check
# description: OpenShift Pod Restart Patterns validation and monitoring
# priority: 740
# Identifies pods with high restart counts or crash loops

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

is_required_file "${RISU_BASE}/common-functions.sh"

# Threshold for restart count
RESTART_THRESHOLD=${RESTART_THRESHOLD:-10}

# Function to check if we're analyzing a Must Gather
is_mustgather() {
    [[ ${RISU_LIVE} != "1" ]] && [[ -d "namespaces" || -d "cluster-scoped-resources" ]]
}

# Function to analyze pod restarts from Must Gather
analyze_pods_mustgather() {
    local high_restart_pods=()
    local crashloop_pods=()

    # Check namespaces directory for pods
    if [[ -d "namespaces" ]]; then
        for ns_dir in namespaces/*; do
            if [[ -d ${ns_dir} ]]; then
                local namespace=$(basename "${ns_dir}")
                local pods_file="${ns_dir}/core/pods.yaml"

                if [[ -f ${pods_file} ]]; then
                    local current_pod=""
                    local restart_count=0
                    local pod_phase=""

                    while IFS= read -r line; do
                        if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*(.+)$ ]]; then
                            current_pod="${BASH_REMATCH[1]}"
                        elif [[ ${line} =~ ^[[:space:]]*phase:[[:space:]]*(.+)$ ]]; then
                            pod_phase="${BASH_REMATCH[1]}"
                        elif [[ ${line} =~ ^[[:space:]]*restartCount:[[:space:]]*([0-9]+)$ ]]; then
                            restart_count="${BASH_REMATCH[1]}"

                            if [[ ${restart_count} -gt ${RESTART_THRESHOLD} ]]; then
                                high_restart_pods+=("${namespace}/${current_pod}: ${restart_count} restarts")
                            fi
                        elif [[ ${line} =~ ^[[:space:]]*reason:[[:space:]]*CrashLoopBackOff$ ]]; then
                            crashloop_pods+=("${namespace}/${current_pod}: CrashLoopBackOff")
                        fi
                    done <"${pods_file}"
                fi
            fi
        done
    fi

    # Report findings
    local issues_found=false

    if [[ ${#high_restart_pods[@]} -gt 0 ]]; then
        echo "Pods with high restart counts (>${RESTART_THRESHOLD}):" >&2
        printf '%s\n' "${high_restart_pods[@]}" >&2
        issues_found=true
    fi

    if [[ ${#crashloop_pods[@]} -gt 0 ]]; then
        echo "Pods in CrashLoopBackOff state:" >&2
        printf '%s\n' "${crashloop_pods[@]}" >&2
        issues_found=true
    fi

    if [[ ${issues_found} == true ]]; then
        exit ${RC_SKIPPED}
    fi

    return 0
}

# Function to analyze pod restarts from live cluster
analyze_pods_live() {
    if ! command -v oc >/dev/null 2>&1; then
        echo "oc command not found" >&2
        exit ${RC_SKIPPED}
    fi

    # Check if we can connect to cluster
    if ! oc whoami >/dev/null 2>&1; then
        echo "Cannot connect to OpenShift cluster" >&2
        exit ${RC_SKIPPED}
    fi

    local issues_found=false

    # Check for pods with high restart counts
    local high_restart_pods
    high_restart_pods=$(oc get pods --all-namespaces --no-headers | awk -v threshold="${RESTART_THRESHOLD}" '$4 > threshold {print $1"/"$2": "$4" restarts"}')

    if [[ -n ${high_restart_pods} ]]; then
        echo "Pods with high restart counts (>${RESTART_THRESHOLD}):" >&2
        echo "${high_restart_pods}" >&2
        issues_found=true
    fi

    # Check for pods in CrashLoopBackOff state
    local crashloop_pods
    crashloop_pods=$(oc get pods --all-namespaces --no-headers | grep CrashLoopBackOff | awk '{print $1"/"$2": "$3}')

    if [[ -n ${crashloop_pods} ]]; then
        echo "Pods in CrashLoopBackOff state:" >&2
        echo "${crashloop_pods}" >&2
        issues_found=true
    fi

    # Check for pods with recent restarts in last hour
    local recent_restarts
    recent_restarts=$(oc get events --all-namespaces --field-selector reason=Started --sort-by='.lastTimestamp' | grep -E "($(date -u --date='1 hour ago' '+%Y-%m-%dT%H')|$(date -u '+%Y-%m-%dT%H'))" | wc -l)

    if [[ ${recent_restarts} -gt 50 ]]; then
        echo "High number of recent pod restarts detected: ${recent_restarts} in the last hour" >&2
        issues_found=true
    fi

    if [[ ${issues_found} == true ]]; then
        exit ${RC_SKIPPED}
    fi

    return 0
}

# Main execution
if is_mustgather; then
    analyze_pods_mustgather
    result=$?
else
    analyze_pods_live
    result=$?
fi

if [[ ${result} -eq 0 ]]; then
    exit "${RC_OKAY}"
else
    exit "${RC_FAILED}"
fi
