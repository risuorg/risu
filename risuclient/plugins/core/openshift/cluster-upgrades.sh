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

# long_name: OpenShift Cluster Upgrades Validation Check
# description: Checks OpenShift cluster upgrade status and compatibility
# priority: 970

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

is_required_file "${RISU_BASE}/common-functions.sh"

# Function to check if we're analyzing a Must Gather
is_mustgather() {
    [[ ${RISU_LIVE} != "1" ]] && [[ -d "namespaces" || -d "cluster-scoped-resources" ]]
}

# Function to analyze cluster upgrades from Must Gather
analyze_upgrades_mustgather() {
    local upgrade_issues=()

    # Check cluster version and upgrade status
    local cv_file="cluster-scoped-resources/config.openshift.io/clusterversions.yaml"
    if [[ -f ${cv_file} ]]; then
        local current_version=""
        local desired_version=""
        local upgrade_progressing=false
        local upgrade_failing=false

        while IFS= read -r line; do
            if [[ ${line} =~ ^[[:space:]]*version:[[:space:]]*(.+)$ ]]; then
                current_version="${BASH_REMATCH[1]}"
            elif [[ ${line} =~ ^[[:space:]]*image:[[:space:]]*(.+)$ ]]; then
                # Extract version from image tag
                if [[ ${BASH_REMATCH[1]} =~ :v?([0-9]+\.[0-9]+\.[0-9]+) ]]; then
                    desired_version="${BASH_REMATCH[1]}"
                fi
            elif [[ ${line} =~ ^[[:space:]]*type:[[:space:]]*Progressing$ ]]; then
                reading_progressing=true
            elif [[ ${line} =~ ^[[:space:]]*type:[[:space:]]*Failing$ ]]; then
                reading_failing=true
            elif [[ ${reading_progressing} == true ]] && [[ ${line} =~ ^[[:space:]]*status:[[:space:]]*True$ ]]; then
                upgrade_progressing=true
                reading_progressing=false
            elif [[ ${reading_failing} == true ]] && [[ ${line} =~ ^[[:space:]]*status:[[:space:]]*True$ ]]; then
                upgrade_failing=true
                reading_failing=false
            fi
        done <"${cv_file}"

        if [[ ${upgrade_failing} == true ]]; then
            upgrade_issues+=("Cluster upgrade is failing")
        fi

        if [[ ${upgrade_progressing} == true ]]; then
            upgrade_issues+=("Cluster upgrade is in progress: ${current_version} → ${desired_version}")
        fi

        if [[ -n ${current_version} && -n ${desired_version} && ${current_version} != "${desired_version}" ]]; then
            upgrade_issues+=("Version mismatch detected: current=${current_version}, desired=${desired_version}")
        fi
    fi

    # Check cluster operators for upgrade issues
    local co_file="cluster-scoped-resources/config.openshift.io/clusteroperators.yaml"
    if [[ -f ${co_file} ]]; then
        local degraded_operators=()
        local progressing_operators=()
        local current_operator=""
        local operator_degraded=""
        local operator_progressing=""

        while IFS= read -r line; do
            if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*(.+)$ ]]; then
                current_operator="${BASH_REMATCH[1]}"
            elif [[ ${line} =~ ^[[:space:]]*type:[[:space:]]*Degraded$ ]]; then
                reading_degraded=true
            elif [[ ${line} =~ ^[[:space:]]*type:[[:space:]]*Progressing$ ]]; then
                reading_progressing=true
            elif [[ ${reading_degraded} == true ]] && [[ ${line} =~ ^[[:space:]]*status:[[:space:]]*True$ ]]; then
                degraded_operators+=("${current_operator}")
                reading_degraded=false
            elif [[ ${reading_progressing} == true ]] && [[ ${line} =~ ^[[:space:]]*status:[[:space:]]*True$ ]]; then
                progressing_operators+=("${current_operator}")
                reading_progressing=false
            fi
        done <"${co_file}"

        if [[ ${#degraded_operators[@]} -gt 0 ]]; then
            upgrade_issues+=("Degraded operators blocking upgrade: ${degraded_operators[*]}")
        fi

        if [[ ${#progressing_operators[@]} -gt 2 ]]; then
            upgrade_issues+=("Many operators progressing: ${progressing_operators[*]}")
        fi
    fi

    # Check MachineConfigPools for upgrade readiness
    local mcp_file="cluster-scoped-resources/machineconfiguration.openshift.io/machineconfigpools.yaml"
    if [[ -f ${mcp_file} ]]; then
        local degraded_mcps=()
        local updating_mcps=()
        local current_mcp=""

        while IFS= read -r line; do
            if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*(.+)$ ]]; then
                current_mcp="${BASH_REMATCH[1]}"
            elif [[ ${line} =~ ^[[:space:]]*type:[[:space:]]*Degraded$ ]]; then
                reading_degraded=true
            elif [[ ${line} =~ ^[[:space:]]*type:[[:space:]]*Updating$ ]]; then
                reading_updating=true
            elif [[ ${reading_degraded} == true ]] && [[ ${line} =~ ^[[:space:]]*status:[[:space:]]*True$ ]]; then
                degraded_mcps+=("${current_mcp}")
                reading_degraded=false
            elif [[ ${reading_updating} == true ]] && [[ ${line} =~ ^[[:space:]]*status:[[:space:]]*True$ ]]; then
                updating_mcps+=("${current_mcp}")
                reading_updating=false
            fi
        done <"${mcp_file}"

        if [[ ${#degraded_mcps[@]} -gt 0 ]]; then
            upgrade_issues+=("Degraded MachineConfigPools: ${degraded_mcps[*]}")
        fi

        if [[ ${#updating_mcps[@]} -gt 0 ]]; then
            upgrade_issues+=("Updating MachineConfigPools: ${updating_mcps[*]}")
        fi
    fi

    # Check for nodes not ready
    local nodes_file="cluster-scoped-resources/core/nodes.yaml"
    if [[ -f ${nodes_file} ]]; then
        local not_ready_nodes=()
        local current_node=""
        local node_ready=""

        while IFS= read -r line; do
            if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*(.+)$ ]]; then
                current_node="${BASH_REMATCH[1]}"
            elif [[ ${line} =~ ^[[:space:]]*type:[[:space:]]*Ready$ ]]; then
                reading_ready=true
            elif [[ ${reading_ready} == true ]] && [[ ${line} =~ ^[[:space:]]*status:[[:space:]]*(.+)$ ]]; then
                node_ready="${BASH_REMATCH[1]}"
                reading_ready=false

                if [[ ${node_ready} != "True" ]]; then
                    not_ready_nodes+=("${current_node}")
                fi
            fi
        done <"${nodes_file}"

        if [[ ${#not_ready_nodes[@]} -gt 0 ]]; then
            upgrade_issues+=("Not ready nodes: ${not_ready_nodes[*]}")
        fi
    fi

    # Check for certificate expiration
    local cert_issues=()
    if [[ -d "namespaces" ]]; then
        for ns_dir in namespaces/*; do
            if [[ -d ${ns_dir} ]]; then
                local namespace=$(basename "${ns_dir}")
                local secrets_file="${ns_dir}/core/secrets.yaml"

                if [[ -f ${secrets_file} ]]; then
                    local cert_count
                    cert_count=$(grep -c "tls.crt:" "${secrets_file}" 2>/dev/null || echo 0)

                    if [[ ${cert_count} -gt 0 ]]; then
                        cert_issues+=("${namespace}: ${cert_count} certificates to check")
                    fi
                fi
            fi
        done
    fi

    if [[ ${#cert_issues[@]} -gt 0 ]]; then
        upgrade_issues+=("Certificates need expiration check: ${cert_issues[*]}")
    fi

    # Report findings
    if [[ ${#upgrade_issues[@]} -gt 0 ]]; then
        echo "Cluster upgrade issues found:" >&2
        printf '%s\n' "${upgrade_issues[@]}" >&2
        exit ${RC_SKIPPED}
    fi

    return 0
}

# Function to analyze cluster upgrades from live cluster
analyze_upgrades_live() {
    if ! command -v oc >/dev/null 2>&1; then
        echo "oc command not found" >&2
        exit ${RC_SKIPPED}
    fi

    # Check if we can connect to cluster
    if ! oc whoami >/dev/null 2>&1; then
        echo "Cannot connect to OpenShift cluster" >&2
        exit ${RC_SKIPPED}
    fi

    local upgrade_issues=()

    # Check cluster version and upgrade status
    local cv_status
    cv_status=$(oc get clusterversion version -o json 2>/dev/null)

    if [[ -n ${cv_status} ]]; then
        local upgrade_failing
        upgrade_failing=$(echo "${cv_status}" | jq -r '.status.conditions[] | select(.type == "Failing" and .status == "True") | .message' 2>/dev/null)

        if [[ -n ${upgrade_failing} ]]; then
            upgrade_issues+=("Cluster upgrade is failing: ${upgrade_failing}")
        fi

        local upgrade_progressing
        upgrade_progressing=$(echo "${cv_status}" | jq -r '.status.conditions[] | select(.type == "Progressing" and .status == "True") | .message' 2>/dev/null)

        if [[ -n ${upgrade_progressing} ]]; then
            upgrade_issues+=("Cluster upgrade in progress: ${upgrade_progressing}")
        fi
    fi

    # Check available updates
    local available_updates
    available_updates=$(oc adm upgrade 2>/dev/null | grep -c "^[0-9]")

    if [[ ${available_updates} -eq 0 ]]; then
        upgrade_issues+=("No available updates found")
    fi

    # Check cluster operators for upgrade issues
    local degraded_operators
    degraded_operators=$(oc get clusteroperators --no-headers 2>/dev/null | grep -v "True.*False.*False" | awk '{print $1}')

    if [[ -n ${degraded_operators} ]]; then
        upgrade_issues+=("Degraded operators blocking upgrade: ${degraded_operators}")
    fi

    # Check MachineConfigPools for upgrade readiness
    local degraded_mcps
    degraded_mcps=$(oc get machineconfigpool --no-headers 2>/dev/null | grep -v "True.*False.*False" | awk '{print $1}')

    if [[ -n ${degraded_mcps} ]]; then
        upgrade_issues+=("Degraded MachineConfigPools: ${degraded_mcps}")
    fi

    # Check for nodes not ready
    local not_ready_nodes
    not_ready_nodes=$(oc get nodes --no-headers 2>/dev/null | grep -v " Ready " | awk '{print $1}')

    if [[ -n ${not_ready_nodes} ]]; then
        upgrade_issues+=("Not ready nodes: ${not_ready_nodes}")
    fi

    # Check for certificate expiration
    local cert_expiry_check
    cert_expiry_check=$(oc get secrets --all-namespaces --no-headers 2>/dev/null | grep "kubernetes.io/tls" | wc -l)

    if [[ ${cert_expiry_check} -gt 0 ]]; then
        upgrade_issues+=("${cert_expiry_check} certificates need expiration check")
    fi

    # Check for storage capacity
    local storage_issues
    storage_issues=$(oc get pv --no-headers 2>/dev/null | grep -c "Failed")

    if [[ ${storage_issues} -gt 0 ]]; then
        upgrade_issues+=("${storage_issues} failed persistent volumes")
    fi

    # Check for resource constraints
    local resource_issues
    resource_issues=$(oc get nodes --no-headers 2>/dev/null | grep -E "(MemoryPressure|DiskPressure|PIDPressure)" | wc -l)

    if [[ ${resource_issues} -gt 0 ]]; then
        upgrade_issues+=("${resource_issues} nodes with resource pressure")
    fi

    # Check for pending pods
    local pending_pods
    pending_pods=$(oc get pods --all-namespaces --no-headers 2>/dev/null | grep -c "Pending")

    if [[ ${pending_pods} -gt 10 ]]; then
        upgrade_issues+=("Many pending pods: ${pending_pods}")
    fi

    # Check for cluster version operator health
    local cvo_health
    cvo_health=$(oc get clusteroperator version --no-headers 2>/dev/null | awk '{print $2" "$3" "$4}')

    if [[ ${cvo_health} != "True False False" ]]; then
        upgrade_issues+=("Cluster Version Operator not healthy: ${cvo_health}")
    fi

    # Check for etcd health
    local etcd_health
    etcd_health=$(oc get clusteroperator etcd --no-headers 2>/dev/null | awk '{print $2" "$3" "$4}')

    if [[ ${etcd_health} != "True False False" ]]; then
        upgrade_issues+=("etcd operator not healthy: ${etcd_health}")
    fi

    # Check for image registry health
    local registry_health
    registry_health=$(oc get clusteroperator image-registry --no-headers 2>/dev/null | awk '{print $2" "$3" "$4}')

    if [[ ${registry_health} != "True False False" ]]; then
        upgrade_issues+=("Image registry operator not healthy: ${registry_health}")
    fi

    # Check for authentication health
    local auth_health
    auth_health=$(oc get clusteroperator authentication --no-headers 2>/dev/null | awk '{print $2" "$3" "$4}')

    if [[ ${auth_health} != "True False False" ]]; then
        upgrade_issues+=("Authentication operator not healthy: ${auth_health}")
    fi

    # Check for network health
    local network_health
    network_health=$(oc get clusteroperator network --no-headers 2>/dev/null | awk '{print $2" "$3" "$4}')

    if [[ ${network_health} != "True False False" ]]; then
        upgrade_issues+=("Network operator not healthy: ${network_health}")
    fi

    # Check for monitoring health
    local monitoring_health
    monitoring_health=$(oc get clusteroperator monitoring --no-headers 2>/dev/null | awk '{print $2" "$3" "$4}')

    if [[ ${monitoring_health} != "True False False" ]]; then
        upgrade_issues+=("Monitoring operator not healthy: ${monitoring_health}")
    fi

    # Check for backup recommendations
    local etcd_backup
    etcd_backup=$(oc get cronjobs -n openshift-etcd --no-headers 2>/dev/null | grep -c "etcd-backup")

    if [[ ${etcd_backup} -eq 0 ]]; then
        upgrade_issues+=("No etcd backup CronJob found - recommend backing up before upgrade")
    fi

    # Report findings
    if [[ ${#upgrade_issues[@]} -gt 0 ]]; then
        echo "Cluster upgrade issues found:" >&2
        printf '%s\n' "${upgrade_issues[@]}" >&2
        exit ${RC_SKIPPED}
    fi

    return 0
}

# Main execution
if is_mustgather; then
    analyze_upgrades_mustgather
    result=$?
else
    analyze_upgrades_live
    result=$?
fi

if [[ ${result} -eq 0 ]]; then
    exit "${RC_OKAY}"
else
    exit "${RC_FAILED}"
fi
