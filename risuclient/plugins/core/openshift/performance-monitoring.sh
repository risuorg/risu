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

# long_name: OpenShift Performance Monitoring Check
# description: Validates OpenShift performance monitoring setup
# priority: 740

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

is_required_file "${RISU_BASE}/common-functions.sh"

# Performance thresholds
CPU_THRESHOLD=${CPU_THRESHOLD:-80}
MEMORY_THRESHOLD=${MEMORY_THRESHOLD:-80}
DISK_THRESHOLD=${DISK_THRESHOLD:-85}

# Function to check if we're analyzing a Must Gather
is_mustgather() {
    [[ ${RISU_LIVE} != "1" ]] && [[ -d "namespaces" || -d "cluster-scoped-resources" ]]
}

# Function to analyze performance from Must Gather
analyze_performance_mustgather() {
    local performance_issues=()

    # Check node resource usage from metrics
    local nodes_file="cluster-scoped-resources/core/nodes.yaml"
    if [[ -f ${nodes_file} ]]; then
        local resource_pressure_nodes=()
        local current_node=""

        while IFS= read -r line; do
            if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*(.+)$ ]]; then
                current_node="${BASH_REMATCH[1]}"
            elif [[ ${line} =~ ^[[:space:]]*type:[[:space:]]*(MemoryPressure|DiskPressure|PIDPressure)$ ]]; then
                condition_type="${BASH_REMATCH[1]}"
                checking_pressure=true
            elif [[ ${checking_pressure} == true ]] && [[ ${line} =~ ^[[:space:]]*status:[[:space:]]*True$ ]]; then
                resource_pressure_nodes+=("${current_node}: ${condition_type}")
                checking_pressure=false
            elif [[ ${checking_pressure} == true ]] && [[ ${line} =~ ^[[:space:]]*status:[[:space:]]*False$ ]]; then
                checking_pressure=false
            fi
        done <"${nodes_file}"

        if [[ ${#resource_pressure_nodes[@]} -gt 0 ]]; then
            performance_issues+=("Nodes with resource pressure: ${resource_pressure_nodes[*]}")
        fi
    fi

    # Check for HPA (Horizontal Pod Autoscaler) issues
    local hpa_issues=()
    if [[ -d "namespaces" ]]; then
        for ns_dir in namespaces/*; do
            if [[ -d ${ns_dir} ]]; then
                local namespace=$(basename "${ns_dir}")
                local hpa_file="${ns_dir}/autoscaling/horizontalpodautoscalers.yaml"

                if [[ -f ${hpa_file} ]]; then
                    local current_hpa=""
                    local hpa_status=""

                    while IFS= read -r line; do
                        if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*(.+)$ ]]; then
                            current_hpa="${BASH_REMATCH[1]}"
                        elif [[ ${line} =~ ^[[:space:]]*currentReplicas:[[:space:]]*([0-9]+)$ ]]; then
                            current_replicas="${BASH_REMATCH[1]}"
                        elif [[ ${line} =~ ^[[:space:]]*desiredReplicas:[[:space:]]*([0-9]+)$ ]]; then
                            desired_replicas="${BASH_REMATCH[1]}"

                            if [[ ${current_replicas} -ne ${desired_replicas} ]]; then
                                hpa_issues+=("${namespace}/${current_hpa}: current=${current_replicas}, desired=${desired_replicas}")
                            fi
                        fi
                    done <"${hpa_file}"
                fi
            fi
        done
    fi

    if [[ ${#hpa_issues[@]} -gt 0 ]]; then
        performance_issues+=("HPA scaling issues: ${hpa_issues[*]}")
    fi

    # Check for resource quotas and limits
    local quota_issues=()
    if [[ -d "namespaces" ]]; then
        for ns_dir in namespaces/*; do
            if [[ -d ${ns_dir} ]]; then
                local namespace=$(basename "${ns_dir}")
                local quota_file="${ns_dir}/core/resourcequotas.yaml"

                if [[ -f ${quota_file} ]]; then
                    local current_quota=""
                    local quota_used=""
                    local quota_hard=""

                    while IFS= read -r line; do
                        if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*(.+)$ ]]; then
                            current_quota="${BASH_REMATCH[1]}"
                        elif [[ ${line} =~ ^[[:space:]]*requests\.cpu:[[:space:]]*(.+)$ ]]; then
                            quota_used="${BASH_REMATCH[1]}"
                        elif [[ ${line} =~ ^[[:space:]]*hard:$ ]]; then
                            reading_hard=true
                        elif [[ ${reading_hard} == true ]] && [[ ${line} =~ ^[[:space:]]*requests\.cpu:[[:space:]]*(.+)$ ]]; then
                            quota_hard="${BASH_REMATCH[1]}"
                            reading_hard=false

                            # Basic check for quota usage (simplified)
                            if [[ ${quota_used} == "${quota_hard}" ]]; then
                                quota_issues+=("${namespace}/${current_quota}: CPU quota exhausted")
                            fi
                        fi
                    done <"${quota_file}"
                fi
            fi
        done
    fi

    if [[ ${#quota_issues[@]} -gt 0 ]]; then
        performance_issues+=("Resource quota issues: ${quota_issues[*]}")
    fi

    # Check for pods with resource limits
    local pods_without_limits=()
    if [[ -d "namespaces" ]]; then
        for ns_dir in namespaces/*; do
            if [[ -d ${ns_dir} ]]; then
                local namespace=$(basename "${ns_dir}")
                local pods_file="${ns_dir}/core/pods.yaml"

                if [[ -f ${pods_file} ]]; then
                    local current_pod=""
                    local has_limits=false

                    while IFS= read -r line; do
                        if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*(.+)$ ]]; then
                            current_pod="${BASH_REMATCH[1]}"
                            has_limits=false
                        elif [[ ${line} =~ ^[[:space:]]*limits:$ ]]; then
                            has_limits=true
                        elif [[ ${line} =~ ^[[:space:]]*resources:$ ]]; then
                            checking_resources=true
                        elif [[ ${checking_resources} == true ]] && [[ ${line} =~ ^[[:space:]]*phase:[[:space:]]*Running$ ]]; then
                            checking_resources=false
                            if [[ ${has_limits} == false ]]; then
                                pods_without_limits+=("${namespace}/${current_pod}")
                            fi
                        fi
                    done <"${pods_file}"
                fi
            fi
        done
    fi

    if [[ ${#pods_without_limits[@]} -gt 10 ]]; then
        performance_issues+=("Many pods without resource limits: ${#pods_without_limits[@]} pods")
    fi

    # Report findings
    if [[ ${#performance_issues[@]} -gt 0 ]]; then
        echo "Performance issues found:" >&2
        printf '%s\n' "${performance_issues[@]}" >&2
        exit ${RC_SKIPPED}
    fi

    return 0
}

# Function to analyze performance from live cluster
analyze_performance_live() {
    if ! command -v oc >/dev/null 2>&1; then
        echo "oc command not found" >&2
        exit ${RC_SKIPPED}
    fi

    # Check if we can connect to cluster
    if ! oc whoami >/dev/null 2>&1; then
        echo "Cannot connect to OpenShift cluster" >&2
        exit ${RC_SKIPPED}
    fi

    local performance_issues=()

    # Check node resource usage
    local nodes_with_pressure
    nodes_with_pressure=$(oc get nodes --no-headers 2>/dev/null | grep -E "(MemoryPressure|DiskPressure|PIDPressure)" | awk '{print $1}')

    if [[ -n ${nodes_with_pressure} ]]; then
        performance_issues+=("Nodes with resource pressure: ${nodes_with_pressure}")
    fi

    # Check node resource utilization using metrics-server if available
    if oc get apiservice v1beta1.metrics.k8s.io >/dev/null 2>&1; then
        local high_cpu_nodes
        high_cpu_nodes=$(oc top nodes --no-headers 2>/dev/null | awk -v threshold="${CPU_THRESHOLD}" '$3 > threshold {print $1": "$3}')

        if [[ -n ${high_cpu_nodes} ]]; then
            performance_issues+=("High CPU usage nodes (>${CPU_THRESHOLD}%): ${high_cpu_nodes}")
        fi

        local high_memory_nodes
        high_memory_nodes=$(oc top nodes --no-headers 2>/dev/null | awk -v threshold="${MEMORY_THRESHOLD}" '$5 > threshold {print $1": "$5}')

        if [[ -n ${high_memory_nodes} ]]; then
            performance_issues+=("High memory usage nodes (>${MEMORY_THRESHOLD}%): ${high_memory_nodes}")
        fi
    fi

    # Check HPA status
    local hpa_issues
    hpa_issues=$(oc get hpa --all-namespaces --no-headers 2>/dev/null | grep -v "unknown" | awk '$4 != $5 {print $1"/"$2": current="$4", desired="$5}')

    if [[ -n ${hpa_issues} ]]; then
        performance_issues+=("HPA scaling issues: ${hpa_issues}")
    fi

    # Check for resource quotas usage
    local quota_issues
    quota_issues=$(oc get resourcequota --all-namespaces --no-headers 2>/dev/null | grep -E "(100%|exhausted)" | awk '{print $1"/"$2": quota exhausted"}')

    if [[ -n ${quota_issues} ]]; then
        performance_issues+=("Resource quota issues: ${quota_issues}")
    fi

    # Check for pods without resource limits
    local pods_without_limits_count
    pods_without_limits_count=$(oc get pods --all-namespaces -o json 2>/dev/null | jq '[.items[] | select(.spec.containers[].resources.limits == null)] | length' 2>/dev/null || echo 0)

    if [[ ${pods_without_limits_count} -gt 10 ]]; then
        performance_issues+=("Many pods without resource limits: ${pods_without_limits_count} pods")
    fi

    # Check for pods with high resource usage
    if oc get apiservice v1beta1.metrics.k8s.io >/dev/null 2>&1; then
        local high_cpu_pods
        high_cpu_pods=$(oc top pods --all-namespaces --no-headers 2>/dev/null | sort -k3 -nr | head -5 | awk '{print $1"/"$2": "$3}')

        if [[ -n ${high_cpu_pods} ]]; then
            performance_issues+=("Top CPU consuming pods: ${high_cpu_pods}")
        fi

        local high_memory_pods
        high_memory_pods=$(oc top pods --all-namespaces --no-headers 2>/dev/null | sort -k4 -nr | head -5 | awk '{print $1"/"$2": "$4}')

        if [[ -n ${high_memory_pods} ]]; then
            performance_issues+=("Top memory consuming pods: ${high_memory_pods}")
        fi
    fi

    # Check for cluster autoscaler
    if oc get clusterautoscaler default >/dev/null 2>&1; then
        local autoscaler_status
        autoscaler_status=$(oc get clusterautoscaler default -o json 2>/dev/null | jq -r '.status.conditions[] | select(.type == "Available") | .status' 2>/dev/null)

        if [[ ${autoscaler_status} != "True" ]]; then
            performance_issues+=("Cluster autoscaler not available")
        fi
    fi

    # Check for machine autoscaler
    local machine_autoscaler_count
    machine_autoscaler_count=$(oc get machineautoscaler --all-namespaces --no-headers 2>/dev/null | wc -l)

    if [[ ${machine_autoscaler_count} -eq 0 ]]; then
        performance_issues+=("No machine autoscalers configured")
    fi

    # Report findings
    if [[ ${#performance_issues[@]} -gt 0 ]]; then
        echo "Performance issues found:" >&2
        printf '%s\n' "${performance_issues[@]}" >&2
        exit ${RC_SKIPPED}
    fi

    return 0
}

# Main execution
if is_mustgather; then
    analyze_performance_mustgather
    result=$?
else
    analyze_performance_live
    result=$?
fi

if [[ ${result} -eq 0 ]]; then
    exit "${RC_OKAY}"
else
    exit "${RC_FAILED}"
fi
