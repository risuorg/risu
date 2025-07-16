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

# long_name: OpenShift SDN/OVN Networking Health Check
# description: Checks OpenShift SDN networking configuration and health
# priority: 870

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

is_required_file "${RISU_BASE}/common-functions.sh"

# Function to check if we're analyzing a Must Gather
is_mustgather() {
    [[ ${RISU_LIVE} != "1" ]] && [[ -d "namespaces" || -d "cluster-scoped-resources" ]]
}

# Function to analyze networking from Must Gather
analyze_networking_mustgather() {
    local network_issues=()

    # Check network operator health
    local network_co_file="cluster-scoped-resources/config.openshift.io/clusteroperators.yaml"
    if [[ -f ${network_co_file} ]]; then
        local in_network_operator=false
        local network_available=""
        local network_degraded=""

        while IFS= read -r line; do
            if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*network$ ]]; then
                in_network_operator=true
            elif [[ ${in_network_operator} == true ]] && [[ ${line} =~ ^[[:space:]]*type:[[:space:]]*Available$ ]]; then
                reading_available=true
            elif [[ ${in_network_operator} == true ]] && [[ ${line} =~ ^[[:space:]]*type:[[:space:]]*Degraded$ ]]; then
                reading_degraded=true
            elif [[ ${reading_available} == true ]] && [[ ${line} =~ ^[[:space:]]*status:[[:space:]]*(.+)$ ]]; then
                network_available="${BASH_REMATCH[1]}"
                reading_available=false
            elif [[ ${reading_degraded} == true ]] && [[ ${line} =~ ^[[:space:]]*status:[[:space:]]*(.+)$ ]]; then
                network_degraded="${BASH_REMATCH[1]}"
                reading_degraded=false
                break
            fi
        done <"${network_co_file}"

        if [[ ${network_available} != "True" ]]; then
            network_issues+=("Network operator not available: ${network_available}")
        fi

        if [[ ${network_degraded} == "True" ]]; then
            network_issues+=("Network operator degraded: ${network_degraded}")
        fi
    fi

    # Check network configuration
    local network_config_file="cluster-scoped-resources/config.openshift.io/networks.yaml"
    if [[ -f ${network_config_file} ]]; then
        local network_type=""
        local cluster_network=""
        local service_network=""

        while IFS= read -r line; do
            if [[ ${line} =~ ^[[:space:]]*networkType:[[:space:]]*(.+)$ ]]; then
                network_type="${BASH_REMATCH[1]}"
            elif [[ ${line} =~ ^[[:space:]]*clusterNetwork:$ ]]; then
                reading_cluster_network=true
            elif [[ ${line} =~ ^[[:space:]]*serviceNetwork:$ ]]; then
                reading_service_network=true
            elif [[ ${reading_cluster_network} == true ]] && [[ ${line} =~ ^[[:space:]]*-[[:space:]]*cidr:[[:space:]]*(.+)$ ]]; then
                cluster_network="${BASH_REMATCH[1]}"
                reading_cluster_network=false
            elif [[ ${reading_service_network} == true ]] && [[ ${line} =~ ^[[:space:]]*-[[:space:]]*(.+)$ ]]; then
                service_network="${BASH_REMATCH[1]}"
                reading_service_network=false
            fi
        done <"${network_config_file}"

        if [[ -z ${network_type} ]]; then
            network_issues+=("Network type not configured")
        fi

        if [[ -z ${cluster_network} ]]; then
            network_issues+=("Cluster network not configured")
        fi

        if [[ -z ${service_network} ]]; then
            network_issues+=("Service network not configured")
        fi
    fi

    # Check CNI daemonset pods
    local cni_pods_issues=()
    local cni_ns_dirs=("namespaces/openshift-sdn" "namespaces/openshift-ovn-kubernetes")

    for ns_dir in "${cni_ns_dirs[@]}"; do
        if [[ -d ${ns_dir} ]]; then
            local pods_file="${ns_dir}/core/pods.yaml"
            if [[ -f ${pods_file} ]]; then
                local cni_pod_count=0
                local cni_ready_count=0

                while IFS= read -r line; do
                    if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*(sdn|ovnkube)- ]]; then
                        ((cni_pod_count++))
                    elif [[ ${line} =~ ^[[:space:]]*phase:[[:space:]]*Running$ ]]; then
                        ((cni_ready_count++))
                    fi
                done <"${pods_file}"

                if [[ ${cni_pod_count} -gt 0 ]] && [[ ${cni_ready_count} -lt ${cni_pod_count} ]]; then
                    cni_pods_issues+=("CNI pods not ready: ${cni_ready_count}/${cni_pod_count} in ${ns_dir}")
                fi
            fi
        fi
    done

    # Check for DNS issues
    local dns_ns_dir="namespaces/openshift-dns"
    if [[ -d ${dns_ns_dir} ]]; then
        local dns_pods_file="${dns_ns_dir}/core/pods.yaml"
        if [[ -f ${dns_pods_file} ]]; then
            local dns_pod_count=0
            local dns_ready_count=0

            while IFS= read -r line; do
                if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*dns- ]]; then
                    ((dns_pod_count++))
                elif [[ ${line} =~ ^[[:space:]]*phase:[[:space:]]*Running$ ]]; then
                    ((dns_ready_count++))
                fi
            done <"${dns_pods_file}"

            if [[ ${dns_pod_count} -gt 0 ]] && [[ ${dns_ready_count} -lt ${dns_pod_count} ]]; then
                network_issues+=("DNS pods not ready: ${dns_ready_count}/${dns_pod_count}")
            fi
        fi
    fi

    # Add CNI pod issues to network issues
    if [[ ${#cni_pods_issues[@]} -gt 0 ]]; then
        network_issues+=("${cni_pods_issues[@]}")
    fi

    # Report findings
    if [[ ${#network_issues[@]} -gt 0 ]]; then
        echo "Network issues found:" >&2
        printf '%s\n' "${network_issues[@]}" >&2
        exit ${RC_SKIPPED}
    fi

    return 0
}

# Function to analyze networking from live cluster
analyze_networking_live() {
    if ! command -v oc >/dev/null 2>&1; then
        echo "oc command not found" >&2
        exit ${RC_SKIPPED}
    fi

    # Check if we can connect to cluster
    if ! oc whoami >/dev/null 2>&1; then
        echo "Cannot connect to OpenShift cluster" >&2
        exit ${RC_SKIPPED}
    fi

    local network_issues=()

    # Check network operator health
    local network_operator_status
    network_operator_status=$(oc get clusteroperator network --no-headers 2>/dev/null | awk '{print $2" "$3" "$4}')

    if [[ ${network_operator_status} != "True False False" ]]; then
        network_issues+=("Network operator not healthy: ${network_operator_status}")
    fi

    # Check network configuration
    local network_config
    network_config=$(oc get network.config.openshift.io cluster -o json 2>/dev/null)

    if [[ -n ${network_config} ]]; then
        local network_type
        network_type=$(echo "${network_config}" | jq -r '.spec.networkType' 2>/dev/null)

        if [[ -z ${network_type} || ${network_type} == "null" ]]; then
            network_issues+=("Network type not configured")
        fi

        local cluster_network
        cluster_network=$(echo "${network_config}" | jq -r '.spec.clusterNetwork[]?.cidr' 2>/dev/null)

        if [[ -z ${cluster_network} ]]; then
            network_issues+=("Cluster network not configured")
        fi

        local service_network
        service_network=$(echo "${network_config}" | jq -r '.spec.serviceNetwork[]?' 2>/dev/null)

        if [[ -z ${service_network} ]]; then
            network_issues+=("Service network not configured")
        fi
    fi

    # Check CNI daemonset pods
    local cni_namespaces=("openshift-sdn" "openshift-ovn-kubernetes")

    for ns in "${cni_namespaces[@]}"; do
        if oc get namespace "${ns}" >/dev/null 2>&1; then
            local cni_pods_status
            cni_pods_status=$(oc get pods -n "${ns}" --no-headers 2>/dev/null)

            if [[ -n ${cni_pods_status} ]]; then
                local cni_pod_count
                cni_pod_count=$(echo "${cni_pods_status}" | wc -l)

                local cni_ready_count
                cni_ready_count=$(echo "${cni_pods_status}" | grep -c "Running")

                if [[ ${cni_ready_count} -lt ${cni_pod_count} ]]; then
                    network_issues+=("CNI pods not ready in ${ns}: ${cni_ready_count}/${cni_pod_count}")
                fi
            fi
        fi
    done

    # Check DNS pods
    local dns_pods_status
    dns_pods_status=$(oc get pods -n openshift-dns --no-headers 2>/dev/null)

    if [[ -n ${dns_pods_status} ]]; then
        local dns_pod_count
        dns_pod_count=$(echo "${dns_pods_status}" | wc -l)

        local dns_ready_count
        dns_ready_count=$(echo "${dns_pods_status}" | grep -c "Running")

        if [[ ${dns_ready_count} -lt ${dns_pod_count} ]]; then
            network_issues+=("DNS pods not ready: ${dns_ready_count}/${dns_pod_count}")
        fi
    fi

    # Check for network connectivity issues
    local failed_endpoints
    failed_endpoints=$(oc get endpoints --all-namespaces --no-headers 2>/dev/null | grep -c "<none>")

    if [[ ${failed_endpoints} -gt 0 ]]; then
        network_issues+=("${failed_endpoints} endpoints with no backend addresses")
    fi

    # Report findings
    if [[ ${#network_issues[@]} -gt 0 ]]; then
        echo "Network issues found:" >&2
        printf '%s\n' "${network_issues[@]}" >&2
        exit ${RC_SKIPPED}
    fi

    return 0
}

# Main execution
if is_mustgather; then
    analyze_networking_mustgather
    result=$?
else
    analyze_networking_live
    result=$?
fi

if [[ ${result} -eq 0 ]]; then
    exit "${RC_OKAY}"
else
    exit "${RC_FAILED}"
fi
