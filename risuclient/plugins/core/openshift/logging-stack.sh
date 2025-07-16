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

# long_name: OpenShift Logging Stack Health Check
# description: Checks OpenShift logging stack configuration and health
# priority: 740

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

is_required_file "${RISU_BASE}/common-functions.sh"

# Function to check if we're analyzing a Must Gather
is_mustgather() {
    [[ ${RISU_LIVE} != "1" ]] && [[ -d "namespaces" || -d "cluster-scoped-resources" ]]
}

# Function to analyze logging from Must Gather
analyze_logging_mustgather() {
    local logging_issues=()

    # Check logging namespaces
    local logging_namespaces=("openshift-logging" "openshift-operators-redhat")

    for ns in "${logging_namespaces[@]}"; do
        local ns_dir="namespaces/${ns}"

        if [[ ! -d ${ns_dir} ]]; then
            if [[ ${ns} == "openshift-logging" ]]; then
                logging_issues+=("${ns} namespace not found - logging may not be deployed")
            fi
            continue
        fi

        # Check logging pods
        local pods_file="${ns_dir}/core/pods.yaml"
        if [[ -f ${pods_file} ]]; then
            local logging_pods=()
            local failed_pods=()
            local current_pod=""
            local pod_phase=""

            while IFS= read -r line; do
                if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*(.+)$ ]]; then
                    current_pod="${BASH_REMATCH[1]}"
                elif [[ ${line} =~ ^[[:space:]]*phase:[[:space:]]*(.+)$ ]]; then
                    pod_phase="${BASH_REMATCH[1]}"

                    # Check for logging component pods
                    if [[ ${current_pod} =~ (elasticsearch|kibana|fluentd|curator|cluster-logging-operator) ]]; then
                        logging_pods+=("${current_pod}")

                        if [[ ${pod_phase} != "Running" ]]; then
                            failed_pods+=("${ns}/${current_pod}: ${pod_phase}")
                        fi
                    fi
                fi
            done <"${pods_file}"

            if [[ ${#failed_pods[@]} -gt 0 ]]; then
                logging_issues+=("${failed_pods[@]}")
            fi
        fi
    done

    # Check ClusterLogging custom resource
    local logging_ns_dir="namespaces/openshift-logging"
    if [[ -d ${logging_ns_dir} ]]; then
        local cl_file="${logging_ns_dir}/logging.openshift.io/clusterloggings.yaml"
        if [[ -f ${cl_file} ]]; then
            local cl_status=""

            while IFS= read -r line; do
                if [[ ${line} =~ ^[[:space:]]*phase:[[:space:]]*(.+)$ ]]; then
                    cl_status="${BASH_REMATCH[1]}"
                    break
                fi
            done <"${cl_file}"

            if [[ ${cl_status} != "Complete" ]]; then
                logging_issues+=("ClusterLogging not in Complete state: ${cl_status}")
            fi
        else
            logging_issues+=("ClusterLogging custom resource not found")
        fi
    fi

    # Check for Elasticsearch cluster health
    local logging_ns_dir="namespaces/openshift-logging"
    if [[ -d ${logging_ns_dir} ]]; then
        local es_file="${logging_ns_dir}/logging.coreos.com/elasticsearches.yaml"
        if [[ -f ${es_file} ]]; then
            local es_health=""
            local es_nodes=""

            while IFS= read -r line; do
                if [[ ${line} =~ ^[[:space:]]*phase:[[:space:]]*(.+)$ ]]; then
                    es_health="${BASH_REMATCH[1]}"
                elif [[ ${line} =~ ^[[:space:]]*nodeCount:[[:space:]]*([0-9]+)$ ]]; then
                    es_nodes="${BASH_REMATCH[1]}"
                fi
            done <"${es_file}"

            if [[ ${es_health} != "Ready" ]]; then
                logging_issues+=("Elasticsearch cluster not ready: ${es_health}")
            fi

            if [[ -n ${es_nodes} && ${es_nodes} -lt 3 ]]; then
                logging_issues+=("Elasticsearch cluster has less than 3 nodes: ${es_nodes}")
            fi
        fi
    fi

    # Check for log forwarding
    local logging_ns_dir="namespaces/openshift-logging"
    if [[ -d ${logging_ns_dir} ]]; then
        local lf_file="${logging_ns_dir}/logging.openshift.io/logforwarders.yaml"
        if [[ -f ${lf_file} ]]; then
            local lf_count
            lf_count=$(grep -c "^[[:space:]]*name:" "${lf_file}" 2>/dev/null || echo 0)

            if [[ ${lf_count} -eq 0 ]]; then
                logging_issues+=("No log forwarders configured")
            fi
        fi
    fi

    # Check for persistent volumes for logging
    local pv_file="cluster-scoped-resources/core/persistentvolumes.yaml"
    if [[ -f ${pv_file} ]]; then
        local logging_pv_count
        logging_pv_count=$(grep -c "elasticsearch\|kibana" "${pv_file}" 2>/dev/null || echo 0)

        if [[ ${logging_pv_count} -eq 0 ]]; then
            logging_issues+=("No persistent volumes found for logging components")
        fi
    fi

    # Report findings
    if [[ ${#logging_issues[@]} -gt 0 ]]; then
        echo "Logging stack issues found:" >&2
        printf '%s\n' "${logging_issues[@]}" >&2
        exit ${RC_SKIPPED}
    fi

    return 0
}

# Function to analyze logging from live cluster
analyze_logging_live() {
    if ! command -v oc >/dev/null 2>&1; then
        echo "oc command not found" >&2
        exit ${RC_SKIPPED}
    fi

    # Check if we can connect to cluster
    if ! oc whoami >/dev/null 2>&1; then
        echo "Cannot connect to OpenShift cluster" >&2
        exit ${RC_SKIPPED}
    fi

    local logging_issues=()

    # Check if logging namespace exists
    if ! oc get namespace openshift-logging >/dev/null 2>&1; then
        echo "openshift-logging namespace not found - logging may not be deployed" >&2
        exit "${RC_SKIPPED}"
    fi

    # Check cluster-logging-operator
    local clo_status
    clo_status=$(oc get pods -n openshift-logging -l name=cluster-logging-operator --no-headers 2>/dev/null | grep -v "Running" | wc -l)

    if [[ ${clo_status} -gt 0 ]]; then
        logging_issues+=("Cluster logging operator not running")
    fi

    # Check logging stack pods
    local failed_logging_pods
    failed_logging_pods=$(oc get pods -n openshift-logging --no-headers 2>/dev/null | grep -E "(elasticsearch|kibana|fluentd|curator)" | grep -v "Running" | awk '{print $1": "$3}')

    if [[ -n ${failed_logging_pods} ]]; then
        logging_issues+=("Failed logging pods: ${failed_logging_pods}")
    fi

    # Check ClusterLogging custom resource
    local cl_status
    cl_status=$(oc get clusterlogging instance -n openshift-logging -o jsonpath='{.status.logStore.phase}' 2>/dev/null)

    if [[ ${cl_status} != "Ready" ]]; then
        logging_issues+=("ClusterLogging not ready: ${cl_status}")
    fi

    # Check Elasticsearch cluster health
    local es_health
    es_health=$(oc get elasticsearch elasticsearch -n openshift-logging -o jsonpath='{.status.cluster.phase}' 2>/dev/null)

    if [[ ${es_health} != "Ready" ]]; then
        logging_issues+=("Elasticsearch cluster not ready: ${es_health}")
    fi

    # Check Elasticsearch nodes
    local es_nodes
    es_nodes=$(oc get elasticsearch elasticsearch -n openshift-logging -o jsonpath='{.status.cluster.nodeCount}' 2>/dev/null)

    if [[ -n ${es_nodes} && ${es_nodes} -lt 3 ]]; then
        logging_issues+=("Elasticsearch cluster has less than 3 nodes: ${es_nodes}")
    fi

    # Check for log forwarding
    local lf_count
    lf_count=$(oc get logforwarder --all-namespaces --no-headers 2>/dev/null | wc -l)

    if [[ ${lf_count} -eq 0 ]]; then
        logging_issues+=("No log forwarders configured")
    fi

    # Check for persistent volumes for logging
    local logging_pv_count
    logging_pv_count=$(oc get pv --no-headers 2>/dev/null | grep -c "elasticsearch\|kibana")

    if [[ ${logging_pv_count} -eq 0 ]]; then
        logging_issues+=("No persistent volumes found for logging components")
    fi

    # Check Fluentd pods on all nodes
    local node_count
    node_count=$(oc get nodes --no-headers 2>/dev/null | wc -l)

    local fluentd_count
    fluentd_count=$(oc get pods -n openshift-logging -l component=fluentd --no-headers 2>/dev/null | grep Running | wc -l)

    if [[ ${fluentd_count} -lt ${node_count} ]]; then
        logging_issues+=("Fluentd pods not running on all nodes: ${fluentd_count}/${node_count}")
    fi

    # Check for log ingestion rate
    local log_ingestion_issues
    log_ingestion_issues=$(oc get pods -n openshift-logging -l component=fluentd -o json 2>/dev/null | jq -r '.items[] | select(.status.containerStatuses[]?.restartCount > 5) | .metadata.name' 2>/dev/null)

    if [[ -n ${log_ingestion_issues} ]]; then
        logging_issues+=("Fluentd pods with high restart count: ${log_ingestion_issues}")
    fi

    # Check Kibana accessibility
    if oc get route kibana -n openshift-logging >/dev/null 2>&1; then
        local kibana_route
        kibana_route=$(oc get route kibana -n openshift-logging --no-headers 2>/dev/null | awk '{print $2}')

        if [[ -n ${kibana_route} ]]; then
            # Try to check if Kibana is accessible (basic check)
            if ! curl -k -s "https://${kibana_route}" >/dev/null 2>&1; then
                logging_issues+=("Kibana not accessible")
            fi
        fi
    fi

    # Report findings
    if [[ ${#logging_issues[@]} -gt 0 ]]; then
        echo "Logging stack issues found:" >&2
        printf '%s\n' "${logging_issues[@]}" >&2
        exit ${RC_SKIPPED}
    fi

    return 0
}

# Main execution
if is_mustgather; then
    analyze_logging_mustgather
    result=$?
else
    analyze_logging_live
    result=$?
fi

if [[ ${result} -eq 0 ]]; then
    exit "${RC_OKAY}"
else
    exit "${RC_FAILED}"
fi
