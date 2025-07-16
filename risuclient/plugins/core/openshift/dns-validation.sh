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

# long_name: OpenShift DNS Validation Check
# description: Validates OpenShift DNS configuration and resolution
# priority: 840

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

is_required_file "${RISU_BASE}/common-functions.sh"

# Function to check if we're analyzing a Must Gather
is_mustgather() {
    [[ ${RISU_LIVE} != "1" ]] && [[ -d "namespaces" || -d "cluster-scoped-resources" ]]
}

# Function to analyze DNS from Must Gather
analyze_dns_mustgather() {
    local dns_issues=()

    # Check DNS operator
    local dns_co_file="cluster-scoped-resources/config.openshift.io/clusteroperators.yaml"
    if [[ -f ${dns_co_file} ]]; then
        local in_dns_operator=false
        local dns_available=""
        local dns_degraded=""

        while IFS= read -r line; do
            if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*dns$ ]]; then
                in_dns_operator=true
            elif [[ ${in_dns_operator} == true ]] && [[ ${line} =~ ^[[:space:]]*type:[[:space:]]*Available$ ]]; then
                reading_available=true
            elif [[ ${in_dns_operator} == true ]] && [[ ${line} =~ ^[[:space:]]*type:[[:space:]]*Degraded$ ]]; then
                reading_degraded=true
            elif [[ ${reading_available} == true ]] && [[ ${line} =~ ^[[:space:]]*status:[[:space:]]*(.+)$ ]]; then
                dns_available="${BASH_REMATCH[1]}"
                reading_available=false
            elif [[ ${reading_degraded} == true ]] && [[ ${line} =~ ^[[:space:]]*status:[[:space:]]*(.+)$ ]]; then
                dns_degraded="${BASH_REMATCH[1]}"
                reading_degraded=false
                break
            fi
        done <"${dns_co_file}"

        if [[ ${dns_available} != "True" ]]; then
            dns_issues+=("DNS operator not available: ${dns_available}")
        fi

        if [[ ${dns_degraded} == "True" ]]; then
            dns_issues+=("DNS operator degraded: ${dns_degraded}")
        fi
    fi

    # Check DNS pods
    local dns_ns_dir="namespaces/openshift-dns"
    if [[ -d ${dns_ns_dir} ]]; then
        local pods_file="${dns_ns_dir}/core/pods.yaml"
        if [[ -f ${pods_file} ]]; then
            local failed_dns_pods=()
            local dns_pod_count=0
            local current_pod=""
            local pod_phase=""

            while IFS= read -r line; do
                if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*(.+)$ ]]; then
                    current_pod="${BASH_REMATCH[1]}"
                elif [[ ${line} =~ ^[[:space:]]*phase:[[:space:]]*(.+)$ ]]; then
                    pod_phase="${BASH_REMATCH[1]}"

                    if [[ ${current_pod} =~ dns-default ]]; then
                        ((dns_pod_count++))
                        if [[ ${pod_phase} != "Running" ]]; then
                            failed_dns_pods+=("${current_pod}: ${pod_phase}")
                        fi
                    fi
                fi
            done <"${pods_file}"

            if [[ ${#failed_dns_pods[@]} -gt 0 ]]; then
                dns_issues+=("Failed DNS pods: ${failed_dns_pods[*]}")
            fi

            if [[ ${dns_pod_count} -eq 0 ]]; then
                dns_issues+=("No DNS pods found")
            fi
        fi
    fi

    # Check DNS configuration
    local dns_config_file="cluster-scoped-resources/config.openshift.io/dnses.yaml"
    if [[ -f ${dns_config_file} ]]; then
        local cluster_domain=""
        local base_domain=""

        while IFS= read -r line; do
            if [[ ${line} =~ ^[[:space:]]*clusterDomain:[[:space:]]*(.+)$ ]]; then
                cluster_domain="${BASH_REMATCH[1]}"
            elif [[ ${line} =~ ^[[:space:]]*baseDomain:[[:space:]]*(.+)$ ]]; then
                base_domain="${BASH_REMATCH[1]}"
            fi
        done <"${dns_config_file}"

        if [[ -z ${cluster_domain} ]]; then
            dns_issues+=("Cluster domain not configured")
        fi

        if [[ -z ${base_domain} ]]; then
            dns_issues+=("Base domain not configured")
        fi
    fi

    # Check DNS services
    local dns_ns_dir="namespaces/openshift-dns"
    if [[ -d ${dns_ns_dir} ]]; then
        local services_file="${dns_ns_dir}/core/services.yaml"
        if [[ -f ${services_file} ]]; then
            local dns_service_count
            dns_service_count=$(grep -c "^[[:space:]]*name:[[:space:]]*dns-default" "${services_file}" 2>/dev/null || echo 0)

            if [[ ${dns_service_count} -eq 0 ]]; then
                dns_issues+=("DNS service not found")
            fi
        fi
    fi

    # Check for DNS ConfigMap
    local dns_ns_dir="namespaces/openshift-dns"
    if [[ -d ${dns_ns_dir} ]]; then
        local configmaps_file="${dns_ns_dir}/core/configmaps.yaml"
        if [[ -f ${configmaps_file} ]]; then
            local dns_configmap_count
            dns_configmap_count=$(grep -c "dns-default" "${configmaps_file}" 2>/dev/null || echo 0)

            if [[ ${dns_configmap_count} -eq 0 ]]; then
                dns_issues+=("DNS ConfigMap not found")
            fi
        fi
    fi

    # Check node DNS configuration
    local nodes_file="cluster-scoped-resources/core/nodes.yaml"
    if [[ -f ${nodes_file} ]]; then
        local nodes_with_dns_issues=()
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
                    nodes_with_dns_issues+=("${current_node}: not ready")
                fi
            fi
        done <"${nodes_file}"

        if [[ ${#nodes_with_dns_issues[@]} -gt 0 ]]; then
            dns_issues+=("Nodes with potential DNS issues: ${nodes_with_dns_issues[*]}")
        fi
    fi

    # Report findings
    if [[ ${#dns_issues[@]} -gt 0 ]]; then
        echo "DNS issues found:" >&2
        printf '%s\n' "${dns_issues[@]}" >&2
        exit ${RC_SKIPPED}
    fi

    return 0
}

# Function to analyze DNS from live cluster
analyze_dns_live() {
    if ! command -v oc >/dev/null 2>&1; then
        echo "oc command not found" >&2
        exit ${RC_SKIPPED}
    fi

    # Check if we can connect to cluster
    if ! oc whoami >/dev/null 2>&1; then
        echo "Cannot connect to OpenShift cluster" >&2
        exit ${RC_SKIPPED}
    fi

    local dns_issues=()

    # Check DNS operator
    local dns_operator_status
    dns_operator_status=$(oc get clusteroperator dns --no-headers 2>/dev/null | awk '{print $2" "$3" "$4}')

    if [[ ${dns_operator_status} != "True False False" ]]; then
        dns_issues+=("DNS operator not healthy: ${dns_operator_status}")
    fi

    # Check DNS pods
    local failed_dns_pods
    failed_dns_pods=$(oc get pods -n openshift-dns --no-headers 2>/dev/null | grep dns-default | grep -v "Running" | awk '{print $1": "$3}')

    if [[ -n ${failed_dns_pods} ]]; then
        dns_issues+=("Failed DNS pods: ${failed_dns_pods}")
    fi

    # Check DNS pod count vs node count
    local node_count
    node_count=$(oc get nodes --no-headers 2>/dev/null | wc -l)

    local dns_pod_count
    dns_pod_count=$(oc get pods -n openshift-dns -l dns.operator.openshift.io/daemonset-dns=default --no-headers 2>/dev/null | grep Running | wc -l)

    if [[ ${dns_pod_count} -lt ${node_count} ]]; then
        dns_issues+=("DNS pods not running on all nodes: ${dns_pod_count}/${node_count}")
    fi

    # Check DNS configuration
    local dns_config
    dns_config=$(oc get dns.config.openshift.io cluster -o json 2>/dev/null)

    if [[ -n ${dns_config} ]]; then
        local cluster_domain
        cluster_domain=$(echo "${dns_config}" | jq -r '.spec.clusterDomain' 2>/dev/null)

        if [[ -z ${cluster_domain} || ${cluster_domain} == "null" ]]; then
            dns_issues+=("Cluster domain not configured")
        fi

        local base_domain
        base_domain=$(echo "${dns_config}" | jq -r '.spec.baseDomain' 2>/dev/null)

        if [[ -z ${base_domain} || ${base_domain} == "null" ]]; then
            dns_issues+=("Base domain not configured")
        fi
    fi

    # Check DNS services
    local dns_service_count
    dns_service_count=$(oc get services -n openshift-dns --no-headers 2>/dev/null | grep -c "dns-default")

    if [[ ${dns_service_count} -eq 0 ]]; then
        dns_issues+=("DNS service not found")
    fi

    # Check DNS resolution from a test pod
    local dns_test_result
    dns_test_result=$(oc run dns-test --image=busybox --rm -i --restart=Never --timeout=60s -- nslookup kubernetes.default.svc.cluster.local 2>&1)

    if [[ ${dns_test_result} =~ "can't resolve" ]]; then
        dns_issues+=("DNS resolution test failed: cannot resolve kubernetes.default.svc.cluster.local")
    fi

    # Check external DNS resolution
    local external_dns_test
    external_dns_test=$(oc run external-dns-test --image=busybox --rm -i --restart=Never --timeout=60s -- nslookup google.com 2>&1)

    if [[ ${external_dns_test} =~ "can't resolve" ]]; then
        dns_issues+=("External DNS resolution test failed: cannot resolve google.com")
    fi

    # Check CoreDNS ConfigMap
    local coredns_config
    coredns_config=$(oc get configmap dns-default -n openshift-dns -o json 2>/dev/null)

    if [[ -z ${coredns_config} ]]; then
        dns_issues+=("CoreDNS ConfigMap not found")
    fi

    # Check for DNS logs errors
    local dns_log_errors
    dns_log_errors=$(oc logs -n openshift-dns -l dns.operator.openshift.io/daemonset-dns=default --tail=100 2>/dev/null | grep -i error | wc -l)

    if [[ ${dns_log_errors} -gt 20 ]]; then
        dns_issues+=("Many errors in DNS logs: ${dns_log_errors} errors")
    fi

    # Check DNS operator logs
    local dns_operator_log_errors
    dns_operator_log_errors=$(oc logs -n openshift-dns-operator deployment/dns-operator --tail=100 2>/dev/null | grep -i error | wc -l)

    if [[ ${dns_operator_log_errors} -gt 10 ]]; then
        dns_issues+=("Many errors in DNS operator logs: ${dns_operator_log_errors} errors")
    fi

    # Check DNS performance
    local dns_performance
    dns_performance=$(time (oc run dns-perf-test --image=busybox --rm -i --restart=Never --timeout=30s -- nslookup kubernetes.default.svc.cluster.local >/dev/null 2>&1) 2>&1 | grep real | awk '{print $2}')

    if [[ -n ${dns_performance} ]]; then
        local seconds
        seconds=$(echo "${dns_performance}" | sed 's/.*m\([0-9.]*\)s/\1/')

        if [[ $(echo "${seconds} > 2" | bc -l 2>/dev/null) -eq 1 ]]; then
            dns_issues+=("DNS resolution slow: ${dns_performance}")
        fi
    fi

    # Check for DNS cache issues
    local dns_cache_issues
    dns_cache_issues=$(oc get events --all-namespaces --field-selector reason=DNSConfigForming 2>/dev/null | wc -l)

    if [[ ${dns_cache_issues} -gt 10 ]]; then
        dns_issues+=("DNS cache formation issues: ${dns_cache_issues} events")
    fi

    # Report findings
    if [[ ${#dns_issues[@]} -gt 0 ]]; then
        echo "DNS issues found:" >&2
        printf '%s\n' "${dns_issues[@]}" >&2
        exit ${RC_SKIPPED}
    fi

    return 0
}

# Main execution
if is_mustgather; then
    analyze_dns_mustgather
    result=$?
else
    analyze_dns_live
    result=$?
fi

if [[ ${result} -eq 0 ]]; then
    exit "${RC_OKAY}"
else
    exit "${RC_FAILED}"
fi
