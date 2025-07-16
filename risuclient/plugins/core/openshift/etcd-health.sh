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

# long_name: OpenShift etcd Health Check
# description: Checks etcd cluster health and performance in OpenShift
# priority: 980

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

is_required_file "${RISU_BASE}/common-functions.sh"

# Function to check if we're analyzing a Must Gather
is_mustgather() {
    [[ ${RISU_LIVE} != "1" ]] && [[ -d "namespaces" || -d "cluster-scoped-resources" ]]
}

# Function to analyze etcd health from Must Gather
analyze_etcd_mustgather() {
    local etcd_issues=()
    local etcd_ns_dir="namespaces/openshift-etcd"

    if [[ ! -d ${etcd_ns_dir} ]]; then
        echo "etcd namespace data not found in Must Gather" >&2
        exit ${RC_SKIPPED}
    fi

    # Check etcd operator health
    local etcd_co_file="cluster-scoped-resources/config.openshift.io/clusteroperators.yaml"
    if [[ -f ${etcd_co_file} ]]; then
        local in_etcd_operator=false
        local etcd_available=""
        local etcd_degraded=""

        while IFS= read -r line; do
            if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*etcd$ ]]; then
                in_etcd_operator=true
            elif [[ ${in_etcd_operator} == true ]] && [[ ${line} =~ ^[[:space:]]*type:[[:space:]]*Available$ ]]; then
                reading_available=true
            elif [[ ${in_etcd_operator} == true ]] && [[ ${line} =~ ^[[:space:]]*type:[[:space:]]*Degraded$ ]]; then
                reading_degraded=true
            elif [[ ${reading_available} == true ]] && [[ ${line} =~ ^[[:space:]]*status:[[:space:]]*(.+)$ ]]; then
                etcd_available="${BASH_REMATCH[1]}"
                reading_available=false
            elif [[ ${reading_degraded} == true ]] && [[ ${line} =~ ^[[:space:]]*status:[[:space:]]*(.+)$ ]]; then
                etcd_degraded="${BASH_REMATCH[1]}"
                reading_degraded=false
                break
            fi
        done <"${etcd_co_file}"

        if [[ ${etcd_available} != "True" ]]; then
            etcd_issues+=("etcd operator not available: ${etcd_available}")
        fi

        if [[ ${etcd_degraded} == "True" ]]; then
            etcd_issues+=("etcd operator degraded: ${etcd_degraded}")
        fi
    fi

    # Check etcd pods
    local etcd_pods_file="${etcd_ns_dir}/core/pods.yaml"
    if [[ -f ${etcd_pods_file} ]]; then
        local etcd_pod_count=0
        local etcd_ready_count=0

        while IFS= read -r line; do
            if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*etcd- ]]; then
                ((etcd_pod_count++))
            elif [[ ${line} =~ ^[[:space:]]*phase:[[:space:]]*Running$ ]]; then
                ((etcd_ready_count++))
            fi
        done <"${etcd_pods_file}"

        if [[ ${etcd_pod_count} -lt 3 ]]; then
            etcd_issues+=("etcd cluster has less than 3 members: ${etcd_pod_count}")
        fi

        if [[ ${etcd_ready_count} -lt ${etcd_pod_count} ]]; then
            etcd_issues+=("Not all etcd pods are running: ${etcd_ready_count}/${etcd_pod_count}")
        fi
    fi

    # Check etcd endpoints
    local etcd_endpoints_file="${etcd_ns_dir}/core/endpoints.yaml"
    if [[ -f ${etcd_endpoints_file} ]]; then
        local etcd_endpoints_count
        etcd_endpoints_count=$(grep -c "ip:" "${etcd_endpoints_file}" 2>/dev/null || echo 0)

        if [[ ${etcd_endpoints_count} -lt 3 ]]; then
            etcd_issues+=("etcd has less than 3 endpoints: ${etcd_endpoints_count}")
        fi
    fi

    # Check for etcd backup CronJob
    local etcd_backup_file="${etcd_ns_dir}/batch/cronjobs.yaml"
    if [[ -f ${etcd_backup_file} ]]; then
        if ! grep -q "etcd-backup" "${etcd_backup_file}"; then
            etcd_issues+=("etcd backup CronJob not found")
        fi
    fi

    # Report findings
    if [[ ${#etcd_issues[@]} -gt 0 ]]; then
        echo "etcd cluster issues found:" >&2
        printf '%s\n' "${etcd_issues[@]}" >&2
        exit ${RC_SKIPPED}
    fi

    return 0
}

# Function to analyze etcd health from live cluster
analyze_etcd_live() {
    if ! command -v oc >/dev/null 2>&1; then
        echo "oc command not found" >&2
        exit ${RC_SKIPPED}
    fi

    # Check if we can connect to cluster
    if ! oc whoami >/dev/null 2>&1; then
        echo "Cannot connect to OpenShift cluster" >&2
        exit ${RC_SKIPPED}
    fi

    local etcd_issues=()

    # Check etcd operator health
    local etcd_operator_status
    etcd_operator_status=$(oc get clusteroperator etcd --no-headers 2>/dev/null | awk '{print $2" "$3" "$4}')

    if [[ ${etcd_operator_status} != "True False False" ]]; then
        etcd_issues+=("etcd operator not healthy: ${etcd_operator_status}")
    fi

    # Check etcd pods
    local etcd_pods_status
    etcd_pods_status=$(oc get pods -n openshift-etcd -l app=etcd --no-headers 2>/dev/null)

    if [[ -z ${etcd_pods_status} ]]; then
        etcd_issues+=("No etcd pods found")
    else
        local etcd_pod_count
        etcd_pod_count=$(echo "${etcd_pods_status}" | wc -l)

        local etcd_ready_count
        etcd_ready_count=$(echo "${etcd_pods_status}" | grep -c "Running")

        if [[ ${etcd_pod_count} -lt 3 ]]; then
            etcd_issues+=("etcd cluster has less than 3 members: ${etcd_pod_count}")
        fi

        if [[ ${etcd_ready_count} -lt ${etcd_pod_count} ]]; then
            etcd_issues+=("Not all etcd pods are running: ${etcd_ready_count}/${etcd_pod_count}")
        fi
    fi

    # Check etcd endpoints
    local etcd_endpoints
    etcd_endpoints=$(oc get endpoints -n openshift-etcd etcd --no-headers 2>/dev/null | awk '{print $2}')

    if [[ -n ${etcd_endpoints} ]]; then
        local endpoint_count
        endpoint_count=$(echo "${etcd_endpoints}" | tr ',' '\n' | wc -l)

        if [[ ${endpoint_count} -lt 3 ]]; then
            etcd_issues+=("etcd has less than 3 endpoints: ${endpoint_count}")
        fi
    fi

    # Check etcd cluster health (if etcdctl is available)
    if command -v etcdctl >/dev/null 2>&1; then
        local etcd_health
        etcd_health=$(oc exec -n openshift-etcd deployment/etcd-operator -- etcdctl endpoint health --cluster 2>/dev/null)

        if [[ -n ${etcd_health} ]]; then
            local unhealthy_endpoints
            unhealthy_endpoints=$(echo "${etcd_health}" | grep -c "unhealthy")

            if [[ ${unhealthy_endpoints} -gt 0 ]]; then
                etcd_issues+=("etcd cluster has ${unhealthy_endpoints} unhealthy endpoints")
            fi
        fi
    fi

    # Check for etcd backup CronJob
    local etcd_backup_cronjob
    etcd_backup_cronjob=$(oc get cronjobs -n openshift-etcd --no-headers 2>/dev/null | grep -c "etcd-backup")

    if [[ ${etcd_backup_cronjob} -eq 0 ]]; then
        etcd_issues+=("etcd backup CronJob not found")
    fi

    # Report findings
    if [[ ${#etcd_issues[@]} -gt 0 ]]; then
        echo "etcd cluster issues found:" >&2
        printf '%s\n' "${etcd_issues[@]}" >&2
        exit ${RC_SKIPPED}
    fi

    return 0
}

# Main execution
if is_mustgather; then
    analyze_etcd_mustgather
    result=$?
else
    analyze_etcd_live
    result=$?
fi

if [[ ${result} -eq 0 ]]; then
    exit "${RC_OKAY}"
else
    exit "${RC_FAILED}"
fi
