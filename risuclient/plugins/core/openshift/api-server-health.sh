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

# long_name: OpenShift API Server Health Check
# description: Validates OpenShift API server health and performance
# priority: 970

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

is_required_file "${RISU_BASE}/common-functions.sh"

# Function to check if we're analyzing a Must Gather
is_mustgather() {
    [[ ${RISU_LIVE} != "1" ]] && [[ -d "namespaces" || -d "cluster-scoped-resources" ]]
}

# Function to analyze API server from Must Gather
analyze_apiserver_mustgather() {
    local apiserver_issues=()

    # Check kube-apiserver operator
    local kube_apiserver_co_file="cluster-scoped-resources/config.openshift.io/clusteroperators.yaml"
    if [[ -f ${kube_apiserver_co_file} ]]; then
        local in_kube_apiserver_operator=false
        local kube_apiserver_available=""
        local kube_apiserver_degraded=""

        while IFS= read -r line; do
            if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*kube-apiserver$ ]]; then
                in_kube_apiserver_operator=true
            elif [[ ${in_kube_apiserver_operator} == true ]] && [[ ${line} =~ ^[[:space:]]*type:[[:space:]]*Available$ ]]; then
                reading_available=true
            elif [[ ${in_kube_apiserver_operator} == true ]] && [[ ${line} =~ ^[[:space:]]*type:[[:space:]]*Degraded$ ]]; then
                reading_degraded=true
            elif [[ ${reading_available} == true ]] && [[ ${line} =~ ^[[:space:]]*status:[[:space:]]*(.+)$ ]]; then
                kube_apiserver_available="${BASH_REMATCH[1]}"
                reading_available=false
            elif [[ ${reading_degraded} == true ]] && [[ ${line} =~ ^[[:space:]]*status:[[:space:]]*(.+)$ ]]; then
                kube_apiserver_degraded="${BASH_REMATCH[1]}"
                reading_degraded=false
                break
            fi
        done <"${kube_apiserver_co_file}"

        if [[ ${kube_apiserver_available} != "True" ]]; then
            apiserver_issues+=("kube-apiserver operator not available: ${kube_apiserver_available}")
        fi

        if [[ ${kube_apiserver_degraded} == "True" ]]; then
            apiserver_issues+=("kube-apiserver operator degraded: ${kube_apiserver_degraded}")
        fi
    fi

    # Check openshift-apiserver operator
    local openshift_apiserver_co_file="cluster-scoped-resources/config.openshift.io/clusteroperators.yaml"
    if [[ -f ${openshift_apiserver_co_file} ]]; then
        local in_openshift_apiserver_operator=false
        local openshift_apiserver_available=""
        local openshift_apiserver_degraded=""

        while IFS= read -r line; do
            if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*openshift-apiserver$ ]]; then
                in_openshift_apiserver_operator=true
            elif [[ ${in_openshift_apiserver_operator} == true ]] && [[ ${line} =~ ^[[:space:]]*type:[[:space:]]*Available$ ]]; then
                reading_available=true
            elif [[ ${in_openshift_apiserver_operator} == true ]] && [[ ${line} =~ ^[[:space:]]*type:[[:space:]]*Degraded$ ]]; then
                reading_degraded=true
            elif [[ ${reading_available} == true ]] && [[ ${line} =~ ^[[:space:]]*status:[[:space:]]*(.+)$ ]]; then
                openshift_apiserver_available="${BASH_REMATCH[1]}"
                reading_available=false
            elif [[ ${reading_degraded} == true ]] && [[ ${line} =~ ^[[:space:]]*status:[[:space:]]*(.+)$ ]]; then
                openshift_apiserver_degraded="${BASH_REMATCH[1]}"
                reading_degraded=false
                break
            fi
        done <"${openshift_apiserver_co_file}"

        if [[ ${openshift_apiserver_available} != "True" ]]; then
            apiserver_issues+=("openshift-apiserver operator not available: ${openshift_apiserver_available}")
        fi

        if [[ ${openshift_apiserver_degraded} == "True" ]]; then
            apiserver_issues+=("openshift-apiserver operator degraded: ${openshift_apiserver_degraded}")
        fi
    fi

    # Check API server pods
    local apiserver_namespaces=("openshift-kube-apiserver" "openshift-apiserver")

    for ns in "${apiserver_namespaces[@]}"; do
        local ns_dir="namespaces/${ns}"
        if [[ -d ${ns_dir} ]]; then
            local pods_file="${ns_dir}/core/pods.yaml"
            if [[ -f ${pods_file} ]]; then
                local failed_apiserver_pods=()
                local current_pod=""
                local pod_phase=""

                while IFS= read -r line; do
                    if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*(.+)$ ]]; then
                        current_pod="${BASH_REMATCH[1]}"
                    elif [[ ${line} =~ ^[[:space:]]*phase:[[:space:]]*(.+)$ ]]; then
                        pod_phase="${BASH_REMATCH[1]}"

                        if [[ ${current_pod} =~ (apiserver|kube-apiserver|openshift-apiserver) ]]; then
                            if [[ ${pod_phase} != "Running" ]]; then
                                failed_apiserver_pods+=("${ns}/${current_pod}: ${pod_phase}")
                            fi
                        fi
                    fi
                done <"${pods_file}"

                if [[ ${#failed_apiserver_pods[@]} -gt 0 ]]; then
                    apiserver_issues+=("${failed_apiserver_pods[@]}")
                fi
            fi
        fi
    done

    # Check API server certificates
    local cert_issues=()
    for ns in "${apiserver_namespaces[@]}"; do
        local ns_dir="namespaces/${ns}"
        if [[ -d ${ns_dir} ]]; then
            local secrets_file="${ns_dir}/core/secrets.yaml"
            if [[ -f ${secrets_file} ]]; then
                local cert_count
                cert_count=$(grep -c "serving-cert\|client-cert" "${secrets_file}" 2>/dev/null || echo 0)

                if [[ ${cert_count} -eq 0 ]]; then
                    cert_issues+=("No API server certificates found in ${ns}")
                fi
            fi
        fi
    done

    if [[ ${#cert_issues[@]} -gt 0 ]]; then
        apiserver_issues+=("${cert_issues[@]}")
    fi

    # Check API server endpoints
    local endpoint_issues=()
    for ns in "${apiserver_namespaces[@]}"; do
        local ns_dir="namespaces/${ns}"
        if [[ -d ${ns_dir} ]]; then
            local endpoints_file="${ns_dir}/core/endpoints.yaml"
            if [[ -f ${endpoints_file} ]]; then
                local endpoint_count
                endpoint_count=$(grep -c "ip:" "${endpoints_file}" 2>/dev/null || echo 0)

                if [[ ${endpoint_count} -eq 0 ]]; then
                    endpoint_issues+=("No API server endpoints found in ${ns}")
                fi
            fi
        fi
    done

    if [[ ${#endpoint_issues[@]} -gt 0 ]]; then
        apiserver_issues+=("${endpoint_issues[@]}")
    fi

    # Report findings
    if [[ ${#apiserver_issues[@]} -gt 0 ]]; then
        echo "API server issues found:" >&2
        printf '%s\n' "${apiserver_issues[@]}" >&2
        exit ${RC_SKIPPED}
    fi

    return 0
}

# Function to analyze API server from live cluster
analyze_apiserver_live() {
    if ! command -v oc >/dev/null 2>&1; then
        echo "oc command not found" >&2
        exit ${RC_SKIPPED}
    fi

    # Check if we can connect to cluster
    if ! oc whoami >/dev/null 2>&1; then
        echo "Cannot connect to OpenShift cluster" >&2
        exit ${RC_SKIPPED}
    fi

    local apiserver_issues=()

    # Check kube-apiserver operator
    local kube_apiserver_operator_status
    kube_apiserver_operator_status=$(oc get clusteroperator kube-apiserver --no-headers 2>/dev/null | awk '{print $2" "$3" "$4}')

    if [[ ${kube_apiserver_operator_status} != "True False False" ]]; then
        apiserver_issues+=("kube-apiserver operator not healthy: ${kube_apiserver_operator_status}")
    fi

    # Check openshift-apiserver operator
    local openshift_apiserver_operator_status
    openshift_apiserver_operator_status=$(oc get clusteroperator openshift-apiserver --no-headers 2>/dev/null | awk '{print $2" "$3" "$4}')

    if [[ ${openshift_apiserver_operator_status} != "True False False" ]]; then
        apiserver_issues+=("openshift-apiserver operator not healthy: ${openshift_apiserver_operator_status}")
    fi

    # Check API server pods
    local apiserver_namespaces=("openshift-kube-apiserver" "openshift-apiserver")

    for ns in "${apiserver_namespaces[@]}"; do
        local failed_apiserver_pods
        failed_apiserver_pods=$(oc get pods -n "${ns}" --no-headers 2>/dev/null | grep -E "(apiserver|kube-apiserver|openshift-apiserver)" | grep -v "Running" | awk '{print $1": "$3}')

        if [[ -n ${failed_apiserver_pods} ]]; then
            apiserver_issues+=("Failed API server pods in ${ns}: ${failed_apiserver_pods}")
        fi
    done

    # Check API server availability
    local api_health
    api_health=$(oc get --raw='/healthz' 2>/dev/null)

    if [[ ${api_health} != "ok" ]]; then
        apiserver_issues+=("API server healthz endpoint not ok: ${api_health}")
    fi

    # Check API server readiness
    local api_readiness
    api_readiness=$(oc get --raw='/readyz' 2>/dev/null)

    if [[ ${api_readiness} != "ok" ]]; then
        apiserver_issues+=("API server readyz endpoint not ok: ${api_readiness}")
    fi

    # Check API server certificates
    local cert_issues=()
    for ns in "${apiserver_namespaces[@]}"; do
        local cert_count
        cert_count=$(oc get secrets -n "${ns}" --no-headers 2>/dev/null | grep -c "serving-cert\|client-cert")

        if [[ ${cert_count} -eq 0 ]]; then
            cert_issues+=("No API server certificates found in ${ns}")
        fi
    done

    if [[ ${#cert_issues[@]} -gt 0 ]]; then
        apiserver_issues+=("${cert_issues[@]}")
    fi

    # Check API server endpoints
    local endpoint_issues=()
    for ns in "${apiserver_namespaces[@]}"; do
        local endpoint_count
        endpoint_count=$(oc get endpoints -n "${ns}" --no-headers 2>/dev/null | grep -c "api\|apiserver")

        if [[ ${endpoint_count} -eq 0 ]]; then
            endpoint_issues+=("No API server endpoints found in ${ns}")
        fi
    done

    if [[ ${#endpoint_issues[@]} -gt 0 ]]; then
        apiserver_issues+=("${endpoint_issues[@]}")
    fi

    # Check API server response times
    local api_response_time
    api_response_time=$(time (oc get nodes >/dev/null 2>&1) 2>&1 | grep real | awk '{print $2}')

    if [[ -n ${api_response_time} ]]; then
        # Extract seconds from time format (e.g., 0m1.234s)
        local seconds
        seconds=$(echo "${api_response_time}" | sed 's/.*m\([0-9.]*\)s/\1/')

        if [[ $(echo "${seconds} > 5" | bc -l 2>/dev/null) -eq 1 ]]; then
            apiserver_issues+=("API server response time slow: ${api_response_time}")
        fi
    fi

    # Check for API server errors in logs
    local api_log_errors
    api_log_errors=$(oc logs -n openshift-kube-apiserver deployment/kube-apiserver-operator --tail=100 2>/dev/null | grep -i error | wc -l)

    if [[ ${api_log_errors} -gt 10 ]]; then
        apiserver_issues+=("Many errors in kube-apiserver logs: ${api_log_errors} errors")
    fi

    # Check API server admission controllers
    local admission_controllers
    admission_controllers=$(oc get --raw='/api/v1/namespaces/openshift-kube-apiserver/configmaps/config' 2>/dev/null | jq -r '.data."config.yaml"' | grep -c "admission-control-config-file")

    if [[ ${admission_controllers} -eq 0 ]]; then
        apiserver_issues+=("No admission controllers configuration found")
    fi

    # Check API server audit logs
    local audit_logs
    audit_logs=$(oc get configmap -n openshift-kube-apiserver --no-headers 2>/dev/null | grep -c "audit")

    if [[ ${audit_logs} -eq 0 ]]; then
        apiserver_issues+=("No audit log configuration found")
    fi

    # Report findings
    if [[ ${#apiserver_issues[@]} -gt 0 ]]; then
        echo "API server issues found:" >&2
        printf '%s\n' "${apiserver_issues[@]}" >&2
        exit ${RC_SKIPPED}
    fi

    return 0
}

# Main execution
if is_mustgather; then
    analyze_apiserver_mustgather
    result=$?
else
    analyze_apiserver_live
    result=$?
fi

if [[ ${result} -eq 0 ]]; then
    exit "${RC_OKAY}"
else
    exit "${RC_FAILED}"
fi
