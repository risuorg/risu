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

# long_name: OpenShift Monitoring Stack Health Check
# description: Checks OpenShift monitoring stack configuration and health
# priority: 740

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

is_required_file "${RISU_BASE}/common-functions.sh"

# Function to check if we're analyzing a Must Gather
is_mustgather() {
    [[ ${RISU_LIVE} != "1" ]] && [[ -d "namespaces" || -d "cluster-scoped-resources" ]]
}

# Function to analyze monitoring from Must Gather
analyze_monitoring_mustgather() {
    local monitoring_issues=()

    # Check monitoring namespaces
    local monitoring_namespaces=("openshift-monitoring" "openshift-user-workload-monitoring")

    for ns in "${monitoring_namespaces[@]}"; do
        local ns_dir="namespaces/${ns}"

        if [[ ! -d ${ns_dir} ]]; then
            monitoring_issues+=("${ns} namespace not found")
            continue
        fi

        # Check monitoring pods
        local pods_file="${ns_dir}/core/pods.yaml"
        if [[ -f ${pods_file} ]]; then
            local monitoring_pods=()
            local failed_pods=()
            local current_pod=""
            local pod_phase=""

            while IFS= read -r line; do
                if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*(.+)$ ]]; then
                    current_pod="${BASH_REMATCH[1]}"
                elif [[ ${line} =~ ^[[:space:]]*phase:[[:space:]]*(.+)$ ]]; then
                    pod_phase="${BASH_REMATCH[1]}"

                    # Check for monitoring component pods
                    if [[ ${current_pod} =~ (prometheus|grafana|alertmanager|node-exporter|kube-state-metrics|thanos) ]]; then
                        monitoring_pods+=("${current_pod}")

                        if [[ ${pod_phase} != "Running" ]]; then
                            failed_pods+=("${ns}/${current_pod}: ${pod_phase}")
                        fi
                    fi
                fi
            done <"${pods_file}"

            if [[ ${#failed_pods[@]} -gt 0 ]]; then
                monitoring_issues+=("${failed_pods[@]}")
            fi
        fi

        # Check monitoring services
        local services_file="${ns_dir}/core/services.yaml"
        if [[ -f ${services_file} ]]; then
            local monitoring_services=0

            while IFS= read -r line; do
                if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*(prometheus|grafana|alertmanager|node-exporter|kube-state-metrics|thanos)- ]]; then
                    ((monitoring_services++))
                fi
            done <"${services_file}"

            if [[ ${monitoring_services} -eq 0 ]]; then
                monitoring_issues+=("No monitoring services found in ${ns}")
            fi
        fi
    done

    # Check monitoring operator
    local monitoring_co_file="cluster-scoped-resources/config.openshift.io/clusteroperators.yaml"
    if [[ -f ${monitoring_co_file} ]]; then
        local in_monitoring_operator=false
        local monitoring_available=""
        local monitoring_degraded=""

        while IFS= read -r line; do
            if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*monitoring$ ]]; then
                in_monitoring_operator=true
            elif [[ ${in_monitoring_operator} == true ]] && [[ ${line} =~ ^[[:space:]]*type:[[:space:]]*Available$ ]]; then
                reading_available=true
            elif [[ ${in_monitoring_operator} == true ]] && [[ ${line} =~ ^[[:space:]]*type:[[:space:]]*Degraded$ ]]; then
                reading_degraded=true
            elif [[ ${reading_available} == true ]] && [[ ${line} =~ ^[[:space:]]*status:[[:space:]]*(.+)$ ]]; then
                monitoring_available="${BASH_REMATCH[1]}"
                reading_available=false
            elif [[ ${reading_degraded} == true ]] && [[ ${line} =~ ^[[:space:]]*status:[[:space:]]*(.+)$ ]]; then
                monitoring_degraded="${BASH_REMATCH[1]}"
                reading_degraded=false
                break
            fi
        done <"${monitoring_co_file}"

        if [[ ${monitoring_available} != "True" ]]; then
            monitoring_issues+=("Monitoring operator not available: ${monitoring_available}")
        fi

        if [[ ${monitoring_degraded} == "True" ]]; then
            monitoring_issues+=("Monitoring operator degraded: ${monitoring_degraded}")
        fi
    fi

    # Check for persistent volumes for monitoring
    local pv_file="cluster-scoped-resources/core/persistentvolumes.yaml"
    if [[ -f ${pv_file} ]]; then
        local monitoring_pv_count
        monitoring_pv_count=$(grep -c "prometheus\|grafana\|alertmanager" "${pv_file}" 2>/dev/null || echo 0)

        if [[ ${monitoring_pv_count} -eq 0 ]]; then
            monitoring_issues+=("No persistent volumes found for monitoring components")
        fi
    fi

    # Report findings
    if [[ ${#monitoring_issues[@]} -gt 0 ]]; then
        echo "Monitoring stack issues found:" >&2
        printf '%s\n' "${monitoring_issues[@]}" >&2
        exit ${RC_SKIPPED}
    fi

    return 0
}

# Function to analyze monitoring from live cluster
analyze_monitoring_live() {
    if ! command -v oc >/dev/null 2>&1; then
        echo "oc command not found" >&2
        exit ${RC_SKIPPED}
    fi

    # Check if we can connect to cluster
    if ! oc whoami >/dev/null 2>&1; then
        echo "Cannot connect to OpenShift cluster" >&2
        exit ${RC_SKIPPED}
    fi

    local monitoring_issues=()

    # Check monitoring operator
    local monitoring_operator_status
    monitoring_operator_status=$(oc get clusteroperator monitoring --no-headers 2>/dev/null | awk '{print $2" "$3" "$4}')

    if [[ ${monitoring_operator_status} != "True False False" ]]; then
        monitoring_issues+=("Monitoring operator not healthy: ${monitoring_operator_status}")
    fi

    # Check monitoring namespaces
    local monitoring_namespaces=("openshift-monitoring" "openshift-user-workload-monitoring")

    for ns in "${monitoring_namespaces[@]}"; do
        if ! oc get namespace "${ns}" >/dev/null 2>&1; then
            monitoring_issues+=("${ns} namespace not found")
            continue
        fi

        # Check monitoring pods
        local failed_monitoring_pods
        failed_monitoring_pods=$(oc get pods -n "${ns}" --no-headers 2>/dev/null | grep -E "(prometheus|grafana|alertmanager|node-exporter|kube-state-metrics|thanos)" | grep -v "Running" | awk '{print $1": "$3}')

        if [[ -n ${failed_monitoring_pods} ]]; then
            monitoring_issues+=("Failed monitoring pods in ${ns}: ${failed_monitoring_pods}")
        fi

        # Check monitoring services
        local monitoring_services_count
        monitoring_services_count=$(oc get services -n "${ns}" --no-headers 2>/dev/null | grep -E "(prometheus|grafana|alertmanager|node-exporter|kube-state-metrics|thanos)" | wc -l)

        if [[ ${monitoring_services_count} -eq 0 ]]; then
            monitoring_issues+=("No monitoring services found in ${ns}")
        fi
    done

    # Check Prometheus targets
    if oc get route prometheus-k8s -n openshift-monitoring >/dev/null 2>&1; then
        local prometheus_route
        prometheus_route=$(oc get route prometheus-k8s -n openshift-monitoring --no-headers 2>/dev/null | awk '{print $2}')

        if [[ -n ${prometheus_route} ]]; then
            # Try to check if Prometheus is accessible (basic check)
            if ! curl -k -s "https://${prometheus_route}/api/v1/targets" >/dev/null 2>&1; then
                monitoring_issues+=("Prometheus API not accessible")
            fi
        fi
    fi

    # Check Grafana
    if oc get route grafana -n openshift-monitoring >/dev/null 2>&1; then
        local grafana_route
        grafana_route=$(oc get route grafana -n openshift-monitoring --no-headers 2>/dev/null | awk '{print $2}')

        if [[ -n ${grafana_route} ]]; then
            # Try to check if Grafana is accessible (basic check)
            if ! curl -k -s "https://${grafana_route}/api/health" >/dev/null 2>&1; then
                monitoring_issues+=("Grafana API not accessible")
            fi
        fi
    fi

    # Check Alertmanager
    if oc get route alertmanager-main -n openshift-monitoring >/dev/null 2>&1; then
        local alertmanager_route
        alertmanager_route=$(oc get route alertmanager-main -n openshift-monitoring --no-headers 2>/dev/null | awk '{print $2}')

        if [[ -n ${alertmanager_route} ]]; then
            # Try to check if Alertmanager is accessible (basic check)
            if ! curl -k -s "https://${alertmanager_route}/api/v1/status" >/dev/null 2>&1; then
                monitoring_issues+=("Alertmanager API not accessible")
            fi
        fi
    fi

    # Check for persistent volumes for monitoring
    local monitoring_pv_count
    monitoring_pv_count=$(oc get pv --no-headers 2>/dev/null | grep -c "prometheus\|grafana\|alertmanager")

    if [[ ${monitoring_pv_count} -eq 0 ]]; then
        monitoring_issues+=("No persistent volumes found for monitoring components")
    fi

    # Check for firing alerts
    local firing_alerts_count
    firing_alerts_count=$(oc get prometheusrule --all-namespaces --no-headers 2>/dev/null | wc -l)

    if [[ ${firing_alerts_count} -eq 0 ]]; then
        monitoring_issues+=("No Prometheus rules found")
    fi

    # Report findings
    if [[ ${#monitoring_issues[@]} -gt 0 ]]; then
        echo "Monitoring stack issues found:" >&2
        printf '%s\n' "${monitoring_issues[@]}" >&2
        exit ${RC_SKIPPED}
    fi

    return 0
}

# Main execution
if is_mustgather; then
    analyze_monitoring_mustgather
    result=$?
else
    analyze_monitoring_live
    result=$?
fi

if [[ ${result} -eq 0 ]]; then
    exit "${RC_OKAY}"
else
    exit "${RC_FAILED}"
fi
