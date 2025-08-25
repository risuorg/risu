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

# long_name: OpenShift Ingress and Routes Health Check
# description: Validates OpenShift ingress and route configurations
# priority: 740

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

is_required_file "${RISU_BASE}/common-functions.sh"

# Function to check if we're analyzing a Must Gather
is_mustgather() {
    [[ ${RISU_LIVE} != "1" ]] && [[ -d "namespaces" || -d "cluster-scoped-resources" ]]
}

# Function to analyze ingress from Must Gather
analyze_ingress_mustgather() {
    local ingress_issues=()

    # Check ingress operator
    local ingress_co_file="cluster-scoped-resources/config.openshift.io/clusteroperators.yaml"
    if [[ -f ${ingress_co_file} ]]; then
        local in_ingress_operator=false
        local ingress_available=""
        local ingress_degraded=""

        while IFS= read -r line; do
            if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*ingress$ ]]; then
                in_ingress_operator=true
            elif [[ ${in_ingress_operator} == true ]] && [[ ${line} =~ ^[[:space:]]*type:[[:space:]]*Available$ ]]; then
                reading_available=true
            elif [[ ${in_ingress_operator} == true ]] && [[ ${line} =~ ^[[:space:]]*type:[[:space:]]*Degraded$ ]]; then
                reading_degraded=true
            elif [[ ${reading_available} == true ]] && [[ ${line} =~ ^[[:space:]]*status:[[:space:]]*(.+)$ ]]; then
                ingress_available="${BASH_REMATCH[1]}"
                reading_available=false
            elif [[ ${reading_degraded} == true ]] && [[ ${line} =~ ^[[:space:]]*status:[[:space:]]*(.+)$ ]]; then
                ingress_degraded="${BASH_REMATCH[1]}"
                reading_degraded=false
                break
            fi
        done <"${ingress_co_file}"

        if [[ ${ingress_available} != "True" ]]; then
            ingress_issues+=("Ingress operator not available: ${ingress_available}")
        fi

        if [[ ${ingress_degraded} == "True" ]]; then
            ingress_issues+=("Ingress operator degraded: ${ingress_degraded}")
        fi
    fi

    # Check ingress controllers
    local ic_file="cluster-scoped-resources/operator.openshift.io/ingresscontrollers.yaml"
    if [[ -f ${ic_file} ]]; then
        local failed_controllers=()
        local current_controller=""
        local controller_available=""

        while IFS= read -r line; do
            if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*(.+)$ ]]; then
                current_controller="${BASH_REMATCH[1]}"
            elif [[ ${line} =~ ^[[:space:]]*type:[[:space:]]*Available$ ]]; then
                reading_available=true
            elif [[ ${reading_available} == true ]] && [[ ${line} =~ ^[[:space:]]*status:[[:space:]]*(.+)$ ]]; then
                controller_available="${BASH_REMATCH[1]}"
                reading_available=false

                if [[ ${controller_available} != "True" ]]; then
                    failed_controllers+=("${current_controller}: ${controller_available}")
                fi
            fi
        done <"${ic_file}"

        if [[ ${#failed_controllers[@]} -gt 0 ]]; then
            ingress_issues+=("Failed ingress controllers: ${failed_controllers[*]}")
        fi
    fi

    # Check router pods
    local router_ns_dir="namespaces/openshift-ingress"
    if [[ -d ${router_ns_dir} ]]; then
        local pods_file="${router_ns_dir}/core/pods.yaml"
        if [[ -f ${pods_file} ]]; then
            local failed_router_pods=()
            local current_pod=""
            local pod_phase=""

            while IFS= read -r line; do
                if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*(.+)$ ]]; then
                    current_pod="${BASH_REMATCH[1]}"
                elif [[ ${line} =~ ^[[:space:]]*phase:[[:space:]]*(.+)$ ]]; then
                    pod_phase="${BASH_REMATCH[1]}"

                    if [[ ${current_pod} =~ router- ]]; then
                        if [[ ${pod_phase} != "Running" ]]; then
                            failed_router_pods+=("${current_pod}: ${pod_phase}")
                        fi
                    fi
                fi
            done <"${pods_file}"

            if [[ ${#failed_router_pods[@]} -gt 0 ]]; then
                ingress_issues+=("Failed router pods: ${failed_router_pods[*]}")
            fi
        fi
    fi

    # Check routes across namespaces
    local route_issues=()
    if [[ -d "namespaces" ]]; then
        for ns_dir in namespaces/*; do
            if [[ -d ${ns_dir} ]]; then
                local namespace=$(basename "${ns_dir}")
                local routes_file="${ns_dir}/route.openshift.io/routes.yaml"

                if [[ -f ${routes_file} ]]; then
                    local current_route=""
                    local route_admitted=""

                    while IFS= read -r line; do
                        if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*(.+)$ ]]; then
                            current_route="${BASH_REMATCH[1]}"
                        elif [[ ${line} =~ ^[[:space:]]*type:[[:space:]]*Admitted$ ]]; then
                            reading_admitted=true
                        elif [[ ${reading_admitted} == true ]] && [[ ${line} =~ ^[[:space:]]*status:[[:space:]]*(.+)$ ]]; then
                            route_admitted="${BASH_REMATCH[1]}"
                            reading_admitted=false

                            if [[ ${route_admitted} != "True" ]]; then
                                route_issues+=("${namespace}/${current_route}: not admitted")
                            fi
                        fi
                    done <"${routes_file}"
                fi
            fi
        done
    fi

    if [[ ${#route_issues[@]} -gt 0 ]]; then
        ingress_issues+=("Route issues: ${route_issues[*]}")
    fi

    # Check for load balancer services
    local lb_issues=()
    if [[ -d "namespaces" ]]; then
        for ns_dir in namespaces/*; do
            if [[ -d ${ns_dir} ]]; then
                local namespace=$(basename "${ns_dir}")
                local services_file="${ns_dir}/core/services.yaml"

                if [[ -f ${services_file} ]]; then
                    local current_service=""
                    local service_type=""
                    local lb_ingress=""

                    while IFS= read -r line; do
                        if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*(.+)$ ]]; then
                            current_service="${BASH_REMATCH[1]}"
                        elif [[ ${line} =~ ^[[:space:]]*type:[[:space:]]*LoadBalancer$ ]]; then
                            service_type="LoadBalancer"
                        elif [[ ${service_type} == "LoadBalancer" ]] && [[ ${line} =~ ^[[:space:]]*loadBalancer:$ ]]; then
                            reading_lb=true
                        elif [[ ${reading_lb} == true ]] && [[ ${line} =~ ^[[:space:]]*ingress:$ ]]; then
                            reading_ingress=true
                        elif [[ ${reading_ingress} == true ]] && [[ ${line} =~ ^[[:space:]]*-[[:space:]]*ip:[[:space:]]*(.+)$ ]]; then
                            lb_ingress="${BASH_REMATCH[1]}"
                            reading_ingress=false
                            reading_lb=false

                            if [[ -z ${lb_ingress} ]]; then
                                lb_issues+=("${namespace}/${current_service}: LoadBalancer without IP")
                            fi
                        fi
                    done <"${services_file}"
                fi
            fi
        done
    fi

    if [[ ${#lb_issues[@]} -gt 0 ]]; then
        ingress_issues+=("LoadBalancer issues: ${lb_issues[*]}")
    fi

    # Report findings
    if [[ ${#ingress_issues[@]} -gt 0 ]]; then
        echo "Ingress and routes issues found:" >&2
        printf '%s\n' "${ingress_issues[@]}" >&2
        exit ${RC_SKIPPED}
    fi

    return 0
}

# Function to analyze ingress from live cluster
analyze_ingress_live() {
    if ! command -v oc >/dev/null 2>&1; then
        echo "oc command not found" >&2
        exit ${RC_SKIPPED}
    fi

    # Check if we can connect to cluster
    if ! oc whoami >/dev/null 2>&1; then
        echo "Cannot connect to OpenShift cluster" >&2
        exit ${RC_SKIPPED}
    fi

    local ingress_issues=()

    # Check ingress operator
    local ingress_operator_status
    ingress_operator_status=$(oc get clusteroperator ingress --no-headers 2>/dev/null | awk '{print $2" "$3" "$4}')

    if [[ ${ingress_operator_status} != "True False False" ]]; then
        ingress_issues+=("Ingress operator not healthy: ${ingress_operator_status}")
    fi

    # Check ingress controllers
    local failed_controllers
    failed_controllers=$(oc get ingresscontroller --all-namespaces --no-headers 2>/dev/null | grep -v "True" | awk '{print $1"/"$2": "$3}')

    if [[ -n ${failed_controllers} ]]; then
        ingress_issues+=("Failed ingress controllers: ${failed_controllers}")
    fi

    # Check router pods
    local failed_router_pods
    failed_router_pods=$(oc get pods -n openshift-ingress --no-headers 2>/dev/null | grep router | grep -v "Running" | awk '{print $1": "$3}')

    if [[ -n ${failed_router_pods} ]]; then
        ingress_issues+=("Failed router pods: ${failed_router_pods}")
    fi

    # Check for routes not admitted
    local route_issues
    route_issues=$(oc get routes --all-namespaces --no-headers 2>/dev/null | grep -v "Admitted" | awk '{print $1"/"$2": not admitted"}')

    if [[ -n ${route_issues} ]]; then
        ingress_issues+=("Route issues: ${route_issues}")
    fi

    # Check for LoadBalancer services without external IP
    local lb_issues
    lb_issues=$(oc get services --all-namespaces --no-headers 2>/dev/null | grep LoadBalancer | grep "<pending>" | awk '{print $1"/"$2": LoadBalancer pending"}')

    if [[ -n ${lb_issues} ]]; then
        ingress_issues+=("LoadBalancer issues: ${lb_issues}")
    fi

    # Check router performance
    local router_ready_count
    router_ready_count=$(oc get pods -n openshift-ingress -l ingresscontroller.operator.openshift.io/deployment-ingresscontroller=default --no-headers 2>/dev/null | grep "Running" | wc -l)

    if [[ ${router_ready_count} -lt 2 ]]; then
        ingress_issues+=("Less than 2 router pods running: ${router_ready_count}")
    fi

    # Check for certificate issues
    local cert_issues
    cert_issues=$(oc get routes --all-namespaces -o json 2>/dev/null | jq -r '.items[] | select(.spec.tls != null) | select(.status.ingress[0].conditions[]?.type == "TLSTerminationError") | .metadata.namespace + "/" + .metadata.name' 2>/dev/null)

    if [[ -n ${cert_issues} ]]; then
        ingress_issues+=("Routes with TLS termination errors: ${cert_issues}")
    fi

    # Check ingress controller logs for errors
    local ingress_log_errors
    ingress_log_errors=$(oc logs -n openshift-ingress-operator deployment/ingress-operator --tail=100 2>/dev/null | grep -i error | wc -l)

    if [[ ${ingress_log_errors} -gt 10 ]]; then
        ingress_issues+=("Many errors in ingress operator logs: ${ingress_log_errors} errors")
    fi

    # Check for wildcard certificates
    local wildcard_cert_count
    wildcard_cert_count=$(oc get ingresscontroller default -n openshift-ingress-operator -o json 2>/dev/null | jq -r '.spec.defaultCertificate.name' 2>/dev/null)

    if [[ -z ${wildcard_cert_count} || ${wildcard_cert_count} == "null" ]]; then
        ingress_issues+=("No wildcard certificate configured")
    fi

    # Check for service endpoints
    local endpoint_issues
    endpoint_issues=$(oc get endpoints --all-namespaces --no-headers 2>/dev/null | grep "<none>" | wc -l)

    if [[ ${endpoint_issues} -gt 0 ]]; then
        ingress_issues+=("Services with no endpoints: ${endpoint_issues} services")
    fi

    # Report findings
    if [[ ${#ingress_issues[@]} -gt 0 ]]; then
        echo "Ingress and routes issues found:" >&2
        printf '%s\n' "${ingress_issues[@]}" >&2
        exit ${RC_SKIPPED}
    fi

    return 0
}

# Main execution
if is_mustgather; then
    analyze_ingress_mustgather
    result=$?
else
    analyze_ingress_live
    result=$?
fi

if [[ ${result} -eq 0 ]]; then
    exit "${RC_OKAY}"
else
    exit "${RC_FAILED}"
fi
