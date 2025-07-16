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

# long_name: OpenShift Image Registry Health Check
# description: Checks OpenShift image registry configuration and health
# priority: 740

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

is_required_file "${RISU_BASE}/common-functions.sh"

# Function to check if we're analyzing a Must Gather
is_mustgather() {
    [[ ${RISU_LIVE} != "1" ]] && [[ -d "namespaces" || -d "cluster-scoped-resources" ]]
}

# Function to analyze image registry from Must Gather
analyze_registry_mustgather() {
    local registry_issues=()

    # Check image registry operator
    local registry_co_file="cluster-scoped-resources/config.openshift.io/clusteroperators.yaml"
    if [[ -f ${registry_co_file} ]]; then
        local in_registry_operator=false
        local registry_available=""
        local registry_degraded=""

        while IFS= read -r line; do
            if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*image-registry$ ]]; then
                in_registry_operator=true
            elif [[ ${in_registry_operator} == true ]] && [[ ${line} =~ ^[[:space:]]*type:[[:space:]]*Available$ ]]; then
                reading_available=true
            elif [[ ${in_registry_operator} == true ]] && [[ ${line} =~ ^[[:space:]]*type:[[:space:]]*Degraded$ ]]; then
                reading_degraded=true
            elif [[ ${reading_available} == true ]] && [[ ${line} =~ ^[[:space:]]*status:[[:space:]]*(.+)$ ]]; then
                registry_available="${BASH_REMATCH[1]}"
                reading_available=false
            elif [[ ${reading_degraded} == true ]] && [[ ${line} =~ ^[[:space:]]*status:[[:space:]]*(.+)$ ]]; then
                registry_degraded="${BASH_REMATCH[1]}"
                reading_degraded=false
                break
            fi
        done <"${registry_co_file}"

        if [[ ${registry_available} != "True" ]]; then
            registry_issues+=("Image registry operator not available: ${registry_available}")
        fi

        if [[ ${registry_degraded} == "True" ]]; then
            registry_issues+=("Image registry operator degraded: ${registry_degraded}")
        fi
    fi

    # Check image registry configuration
    local registry_config_file="cluster-scoped-resources/imageregistry.operator.openshift.io/configs.yaml"
    if [[ -f ${registry_config_file} ]]; then
        local registry_state=""
        local storage_configured=false

        while IFS= read -r line; do
            if [[ ${line} =~ ^[[:space:]]*managementState:[[:space:]]*(.+)$ ]]; then
                registry_state="${BASH_REMATCH[1]}"
            elif [[ ${line} =~ ^[[:space:]]*storage:$ ]]; then
                storage_configured=true
            fi
        done <"${registry_config_file}"

        if [[ ${registry_state} == "Removed" ]]; then
            registry_issues+=("Image registry is removed/disabled")
        fi

        if [[ ${storage_configured} == false ]]; then
            registry_issues+=("Image registry storage not configured")
        fi
    fi

    # Check registry pods
    local registry_ns_dir="namespaces/openshift-image-registry"
    if [[ -d ${registry_ns_dir} ]]; then
        local pods_file="${registry_ns_dir}/core/pods.yaml"
        if [[ -f ${pods_file} ]]; then
            local failed_registry_pods=()
            local current_pod=""
            local pod_phase=""

            while IFS= read -r line; do
                if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*(.+)$ ]]; then
                    current_pod="${BASH_REMATCH[1]}"
                elif [[ ${line} =~ ^[[:space:]]*phase:[[:space:]]*(.+)$ ]]; then
                    pod_phase="${BASH_REMATCH[1]}"

                    if [[ ${current_pod} =~ (image-registry|cluster-image-registry-operator) ]]; then
                        if [[ ${pod_phase} != "Running" ]]; then
                            failed_registry_pods+=("${current_pod}: ${pod_phase}")
                        fi
                    fi
                fi
            done <"${pods_file}"

            if [[ ${#failed_registry_pods[@]} -gt 0 ]]; then
                registry_issues+=("Failed registry pods: ${failed_registry_pods[*]}")
            fi
        fi
    fi

    # Check registry service
    local registry_ns_dir="namespaces/openshift-image-registry"
    if [[ -d ${registry_ns_dir} ]]; then
        local services_file="${registry_ns_dir}/core/services.yaml"
        if [[ -f ${services_file} ]]; then
            local registry_service_count
            registry_service_count=$(grep -c "image-registry" "${services_file}" 2>/dev/null || echo 0)

            if [[ ${registry_service_count} -eq 0 ]]; then
                registry_issues+=("Image registry service not found")
            fi
        fi
    fi

    # Check registry route
    local registry_ns_dir="namespaces/openshift-image-registry"
    if [[ -d ${registry_ns_dir} ]]; then
        local routes_file="${registry_ns_dir}/route.openshift.io/routes.yaml"
        if [[ -f ${routes_file} ]]; then
            local registry_route_count
            registry_route_count=$(grep -c "default-route" "${routes_file}" 2>/dev/null || echo 0)

            if [[ ${registry_route_count} -eq 0 ]]; then
                registry_issues+=("Image registry route not configured")
            fi
        fi
    fi

    # Check for PVCs for registry storage
    local registry_ns_dir="namespaces/openshift-image-registry"
    if [[ -d ${registry_ns_dir} ]]; then
        local pvc_file="${registry_ns_dir}/core/persistentvolumeclaims.yaml"
        if [[ -f ${pvc_file} ]]; then
            local registry_pvc_count
            registry_pvc_count=$(grep -c "image-registry" "${pvc_file}" 2>/dev/null || echo 0)

            if [[ ${registry_pvc_count} -eq 0 ]]; then
                registry_issues+=("No PVC found for image registry storage")
            fi
        fi
    fi

    # Report findings
    if [[ ${#registry_issues[@]} -gt 0 ]]; then
        echo "Image registry issues found:" >&2
        printf '%s\n' "${registry_issues[@]}" >&2
        exit ${RC_SKIPPED}
    fi

    return 0
}

# Function to analyze image registry from live cluster
analyze_registry_live() {
    if ! command -v oc >/dev/null 2>&1; then
        echo "oc command not found" >&2
        exit ${RC_SKIPPED}
    fi

    # Check if we can connect to cluster
    if ! oc whoami >/dev/null 2>&1; then
        echo "Cannot connect to OpenShift cluster" >&2
        exit ${RC_SKIPPED}
    fi

    local registry_issues=()

    # Check image registry operator
    local registry_operator_status
    registry_operator_status=$(oc get clusteroperator image-registry --no-headers 2>/dev/null | awk '{print $2" "$3" "$4}')

    if [[ ${registry_operator_status} != "True False False" ]]; then
        registry_issues+=("Image registry operator not healthy: ${registry_operator_status}")
    fi

    # Check image registry configuration
    local registry_config
    registry_config=$(oc get config.imageregistry.operator.openshift.io/cluster -o json 2>/dev/null)

    if [[ -n ${registry_config} ]]; then
        local registry_state
        registry_state=$(echo "${registry_config}" | jq -r '.spec.managementState' 2>/dev/null)

        if [[ ${registry_state} == "Removed" ]]; then
            registry_issues+=("Image registry is removed/disabled")
        fi

        local storage_configured
        storage_configured=$(echo "${registry_config}" | jq -r '.spec.storage' 2>/dev/null)

        if [[ ${storage_configured} == "null" || ${storage_configured} == "{}" ]]; then
            registry_issues+=("Image registry storage not configured")
        fi
    fi

    # Check registry pods
    local failed_registry_pods
    failed_registry_pods=$(oc get pods -n openshift-image-registry --no-headers 2>/dev/null | grep -E "(image-registry|cluster-image-registry-operator)" | grep -v "Running" | awk '{print $1": "$3}')

    if [[ -n ${failed_registry_pods} ]]; then
        registry_issues+=("Failed registry pods: ${failed_registry_pods}")
    fi

    # Check registry service
    local registry_service_count
    registry_service_count=$(oc get services -n openshift-image-registry --no-headers 2>/dev/null | grep -c "image-registry")

    if [[ ${registry_service_count} -eq 0 ]]; then
        registry_issues+=("Image registry service not found")
    fi

    # Check registry route
    local registry_route_count
    registry_route_count=$(oc get routes -n openshift-image-registry --no-headers 2>/dev/null | grep -c "default-route")

    if [[ ${registry_route_count} -eq 0 ]]; then
        registry_issues+=("Image registry route not configured")
    fi

    # Check for PVCs for registry storage
    local registry_pvc_count
    registry_pvc_count=$(oc get pvc -n openshift-image-registry --no-headers 2>/dev/null | grep -c "image-registry")

    if [[ ${registry_pvc_count} -eq 0 ]]; then
        registry_issues+=("No PVC found for image registry storage")
    fi

    # Check registry connectivity
    local registry_route
    registry_route=$(oc get route default-route -n openshift-image-registry --no-headers 2>/dev/null | awk '{print $2}')

    if [[ -n ${registry_route} ]]; then
        # Try to check if registry is accessible (basic check)
        if ! curl -k -s "https://${registry_route}/healthz" >/dev/null 2>&1; then
            registry_issues+=("Image registry not accessible via route")
        fi
    fi

    # Check registry replicas
    local registry_replicas
    registry_replicas=$(oc get deployment image-registry -n openshift-image-registry -o jsonpath='{.status.readyReplicas}' 2>/dev/null)

    if [[ -z ${registry_replicas} || ${registry_replicas} -eq 0 ]]; then
        registry_issues+=("No ready image registry replicas")
    fi

    # Check for image pruning
    local pruning_config
    pruning_config=$(oc get imagepruner.imageregistry.operator.openshift.io/cluster -o json 2>/dev/null)

    if [[ -n ${pruning_config} ]]; then
        local pruning_state
        pruning_state=$(echo "${pruning_config}" | jq -r '.spec.schedule' 2>/dev/null)

        if [[ ${pruning_state} == "null" || -z ${pruning_state} ]]; then
            registry_issues+=("Image pruning not scheduled")
        fi
    fi

    # Check registry logs for errors
    local registry_log_errors
    registry_log_errors=$(oc logs -n openshift-image-registry deployment/image-registry --tail=100 2>/dev/null | grep -i error | wc -l)

    if [[ ${registry_log_errors} -gt 10 ]]; then
        registry_issues+=("Many errors in registry logs: ${registry_log_errors} errors")
    fi

    # Check registry metrics
    local registry_metrics
    registry_metrics=$(oc get servicemonitor -n openshift-image-registry --no-headers 2>/dev/null | grep -c "image-registry")

    if [[ ${registry_metrics} -eq 0 ]]; then
        registry_issues+=("Image registry metrics not configured")
    fi

    # Report findings
    if [[ ${#registry_issues[@]} -gt 0 ]]; then
        echo "Image registry issues found:" >&2
        printf '%s\n' "${registry_issues[@]}" >&2
        exit ${RC_SKIPPED}
    fi

    return 0
}

# Main execution
if is_mustgather; then
    analyze_registry_mustgather
    result=$?
else
    analyze_registry_live
    result=$?
fi

if [[ ${result} -eq 0 ]]; then
    exit "${RC_OKAY}"
else
    exit "${RC_FAILED}"
fi
