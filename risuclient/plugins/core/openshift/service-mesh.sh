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

# long_name: OpenShift Service Mesh Validation Check
# description: Validates OpenShift service mesh configuration
# priority: 740

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

is_required_file "${RISU_BASE}/common-functions.sh"

# Function to check if we're analyzing a Must Gather
is_mustgather() {
    [[ ${RISU_LIVE} != "1" ]] && [[ -d "namespaces" || -d "cluster-scoped-resources" ]]
}

# Function to analyze service mesh from Must Gather
analyze_servicemesh_mustgather() {
    local servicemesh_issues=()

    # Check for service mesh namespaces
    local mesh_namespaces=("istio-system" "openshift-operators" "openshift-service-mesh")
    local mesh_found=false

    for ns in "${mesh_namespaces[@]}"; do
        local ns_dir="namespaces/${ns}"
        if [[ -d ${ns_dir} ]]; then
            mesh_found=true

            # Check service mesh operators
            local operators_file="${ns_dir}/operators.coreos.com/subscriptions.yaml"
            if [[ -f ${operators_file} ]]; then
                local mesh_subs=()
                local current_sub=""
                local sub_state=""

                while IFS= read -r line; do
                    if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*(.+)$ ]]; then
                        current_sub="${BASH_REMATCH[1]}"
                    elif [[ ${line} =~ ^[[:space:]]*state:[[:space:]]*(.+)$ ]]; then
                        sub_state="${BASH_REMATCH[1]}"

                        if [[ ${current_sub} =~ (servicemesh|jaeger|kiali|elasticsearch) ]]; then
                            mesh_subs+=("${current_sub}")

                            if [[ ${sub_state} != "AtLatestKnown" ]]; then
                                servicemesh_issues+=("${ns}/${current_sub}: ${sub_state}")
                            fi
                        fi
                    fi
                done <"${operators_file}"
            fi

            # Check service mesh control plane pods
            local pods_file="${ns_dir}/core/pods.yaml"
            if [[ -f ${pods_file} ]]; then
                local failed_pods=()
                local current_pod=""
                local pod_phase=""

                while IFS= read -r line; do
                    if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*(.+)$ ]]; then
                        current_pod="${BASH_REMATCH[1]}"
                    elif [[ ${line} =~ ^[[:space:]]*phase:[[:space:]]*(.+)$ ]]; then
                        pod_phase="${BASH_REMATCH[1]}"

                        if [[ ${current_pod} =~ (istio|pilot|citadel|galley|mixer|sidecar|jaeger|kiali|prometheus) ]]; then
                            if [[ ${pod_phase} != "Running" ]]; then
                                failed_pods+=("${ns}/${current_pod}: ${pod_phase}")
                            fi
                        fi
                    fi
                done <"${pods_file}"

                if [[ ${#failed_pods[@]} -gt 0 ]]; then
                    servicemesh_issues+=("${failed_pods[@]}")
                fi
            fi
        fi
    done

    if [[ ${mesh_found} == false ]]; then
        echo "No service mesh namespaces found - service mesh may not be deployed" >&2
        exit "${RC_SKIPPED}"
    fi

    # Check ServiceMeshControlPlane
    local smcp_found=false
    if [[ -d "namespaces" ]]; then
        for ns_dir in namespaces/*; do
            if [[ -d ${ns_dir} ]]; then
                local namespace=$(basename "${ns_dir}")
                local smcp_file="${ns_dir}/maistra.io/servicemeshcontrolplanes.yaml"

                if [[ -f ${smcp_file} ]]; then
                    smcp_found=true
                    local smcp_ready=""

                    while IFS= read -r line; do
                        if [[ ${line} =~ ^[[:space:]]*type:[[:space:]]*Ready$ ]]; then
                            reading_ready=true
                        elif [[ ${reading_ready} == true ]] && [[ ${line} =~ ^[[:space:]]*status:[[:space:]]*(.+)$ ]]; then
                            smcp_ready="${BASH_REMATCH[1]}"
                            reading_ready=false

                            if [[ ${smcp_ready} != "True" ]]; then
                                servicemesh_issues+=("${namespace}: ServiceMeshControlPlane not ready")
                            fi
                        fi
                    done <"${smcp_file}"
                fi
            fi
        done
    fi

    if [[ ${smcp_found} == false ]]; then
        servicemesh_issues+=("No ServiceMeshControlPlane found")
    fi

    # Check ServiceMeshMemberRoll
    local smmr_found=false
    if [[ -d "namespaces" ]]; then
        for ns_dir in namespaces/*; do
            if [[ -d ${ns_dir} ]]; then
                local namespace=$(basename "${ns_dir}")
                local smmr_file="${ns_dir}/maistra.io/servicemeshmemberrolls.yaml"

                if [[ -f ${smmr_file} ]]; then
                    smmr_found=true
                    local smmr_ready=""

                    while IFS= read -r line; do
                        if [[ ${line} =~ ^[[:space:]]*type:[[:space:]]*Ready$ ]]; then
                            reading_ready=true
                        elif [[ ${reading_ready} == true ]] && [[ ${line} =~ ^[[:space:]]*status:[[:space:]]*(.+)$ ]]; then
                            smmr_ready="${BASH_REMATCH[1]}"
                            reading_ready=false

                            if [[ ${smmr_ready} != "True" ]]; then
                                servicemesh_issues+=("${namespace}: ServiceMeshMemberRoll not ready")
                            fi
                        fi
                    done <"${smmr_file}"
                fi
            fi
        done
    fi

    if [[ ${smmr_found} == false ]]; then
        servicemesh_issues+=("No ServiceMeshMemberRoll found")
    fi

    # Check for Istio CRDs
    local istio_crds_file="cluster-scoped-resources/apiextensions.k8s.io/customresourcedefinitions.yaml"
    if [[ -f ${istio_crds_file} ]]; then
        local istio_crd_count
        istio_crd_count=$(grep -c "group.*istio.io" "${istio_crds_file}" 2>/dev/null || echo 0)

        if [[ ${istio_crd_count} -eq 0 ]]; then
            servicemesh_issues+=("No Istio CRDs found")
        fi
    fi

    # Report findings
    if [[ ${#servicemesh_issues[@]} -gt 0 ]]; then
        echo "Service mesh issues found:" >&2
        printf '%s\n' "${servicemesh_issues[@]}" >&2
        exit ${RC_SKIPPED}
    fi

    return 0
}

# Function to analyze service mesh from live cluster
analyze_servicemesh_live() {
    if ! command -v oc >/dev/null 2>&1; then
        echo "oc command not found" >&2
        exit ${RC_SKIPPED}
    fi

    # Check if we can connect to cluster
    if ! oc whoami >/dev/null 2>&1; then
        echo "Cannot connect to OpenShift cluster" >&2
        exit ${RC_SKIPPED}
    fi

    local servicemesh_issues=()

    # Check for service mesh namespaces
    local mesh_namespaces=("istio-system" "openshift-operators")
    local mesh_found=false

    for ns in "${mesh_namespaces[@]}"; do
        if oc get namespace "${ns}" >/dev/null 2>&1; then
            mesh_found=true
            break
        fi
    done

    if [[ ${mesh_found} == false ]]; then
        echo "No service mesh namespaces found - service mesh may not be deployed" >&2
        exit "${RC_SKIPPED}"
    fi

    # Check service mesh operators
    local mesh_operators_issues
    mesh_operators_issues=$(oc get subscriptions --all-namespaces --no-headers 2>/dev/null | grep -E "(servicemesh|jaeger|kiali|elasticsearch)" | grep -v "AtLatestKnown" | awk '{print $1"/"$2": "$4}')

    if [[ -n ${mesh_operators_issues} ]]; then
        servicemesh_issues+=("Service mesh operator issues: ${mesh_operators_issues}")
    fi

    # Check service mesh control plane pods
    local failed_mesh_pods
    failed_mesh_pods=$(oc get pods --all-namespaces --no-headers 2>/dev/null | grep -E "(istio|pilot|citadel|galley|mixer|sidecar|jaeger|kiali)" | grep -v "Running" | awk '{print $1"/"$2": "$3}')

    if [[ -n ${failed_mesh_pods} ]]; then
        servicemesh_issues+=("Failed service mesh pods: ${failed_mesh_pods}")
    fi

    # Check ServiceMeshControlPlane
    local smcp_status
    smcp_status=$(oc get servicemeshcontrolplane --all-namespaces --no-headers 2>/dev/null | grep -v "True" | awk '{print $1"/"$2": "$3}')

    if [[ -n ${smcp_status} ]]; then
        servicemesh_issues+=("ServiceMeshControlPlane issues: ${smcp_status}")
    fi

    # Check ServiceMeshMemberRoll
    local smmr_status
    smmr_status=$(oc get servicemeshmemberroll --all-namespaces --no-headers 2>/dev/null | grep -v "True" | awk '{print $1"/"$2": "$3}')

    if [[ -n ${smmr_status} ]]; then
        servicemesh_issues+=("ServiceMeshMemberRoll issues: ${smmr_status}")
    fi

    # Check for Istio CRDs
    local istio_crd_count
    istio_crd_count=$(oc get crd --no-headers 2>/dev/null | grep -c "istio.io")

    if [[ ${istio_crd_count} -eq 0 ]]; then
        servicemesh_issues+=("No Istio CRDs found")
    fi

    # Check sidecar injection
    local injection_issues
    injection_issues=$(oc get namespaces -o json 2>/dev/null | jq -r '.items[] | select(.metadata.labels["maistra.io/member-of"] != null) | select(.metadata.labels["istio-injection"] != "enabled") | .metadata.name' 2>/dev/null | wc -l)

    if [[ ${injection_issues} -gt 0 ]]; then
        servicemesh_issues+=("Namespaces in mesh without sidecar injection: ${injection_issues}")
    fi

    # Check Istio proxy sidecars
    local proxy_issues
    proxy_issues=$(oc get pods --all-namespaces -o json 2>/dev/null | jq -r '.items[] | select(.metadata.labels["maistra.io/member-of"] != null) | select(.spec.containers | map(select(.name == "istio-proxy")) | length == 0) | .metadata.namespace + "/" + .metadata.name' 2>/dev/null | wc -l)

    if [[ ${proxy_issues} -gt 0 ]]; then
        servicemesh_issues+=("Pods in mesh without Istio proxy sidecar: ${proxy_issues}")
    fi

    # Check Istio Gateway
    local gateway_count
    gateway_count=$(oc get gateway --all-namespaces --no-headers 2>/dev/null | wc -l)

    if [[ ${gateway_count} -eq 0 ]]; then
        servicemesh_issues+=("No Istio Gateways found")
    fi

    # Check VirtualService
    local vs_count
    vs_count=$(oc get virtualservice --all-namespaces --no-headers 2>/dev/null | wc -l)

    if [[ ${vs_count} -eq 0 ]]; then
        servicemesh_issues+=("No VirtualServices found")
    fi

    # Check DestinationRule
    local dr_count
    dr_count=$(oc get destinationrule --all-namespaces --no-headers 2>/dev/null | wc -l)

    if [[ ${dr_count} -eq 0 ]]; then
        servicemesh_issues+=("No DestinationRules found")
    fi

    # Check Jaeger
    local jaeger_pods
    jaeger_pods=$(oc get pods --all-namespaces --no-headers 2>/dev/null | grep jaeger | grep -v Running | wc -l)

    if [[ ${jaeger_pods} -gt 0 ]]; then
        servicemesh_issues+=("Jaeger pods not running: ${jaeger_pods}")
    fi

    # Check Kiali
    local kiali_pods
    kiali_pods=$(oc get pods --all-namespaces --no-headers 2>/dev/null | grep kiali | grep -v Running | wc -l)

    if [[ ${kiali_pods} -gt 0 ]]; then
        servicemesh_issues+=("Kiali pods not running: ${kiali_pods}")
    fi

    # Check mTLS policy
    local mtls_issues
    mtls_issues=$(oc get peerauthentication --all-namespaces --no-headers 2>/dev/null | wc -l)

    if [[ ${mtls_issues} -eq 0 ]]; then
        servicemesh_issues+=("No PeerAuthentication policies found")
    fi

    # Check authorization policies
    local authz_policies
    authz_policies=$(oc get authorizationpolicy --all-namespaces --no-headers 2>/dev/null | wc -l)

    if [[ ${authz_policies} -eq 0 ]]; then
        servicemesh_issues+=("No AuthorizationPolicies found")
    fi

    # Check service mesh telemetry
    local telemetry_issues
    telemetry_issues=$(oc get telemetry --all-namespaces --no-headers 2>/dev/null | wc -l)

    if [[ ${telemetry_issues} -eq 0 ]]; then
        servicemesh_issues+=("No Telemetry configurations found")
    fi

    # Report findings
    if [[ ${#servicemesh_issues[@]} -gt 0 ]]; then
        echo "Service mesh issues found:" >&2
        printf '%s\n' "${servicemesh_issues[@]}" >&2
        exit ${RC_SKIPPED}
    fi

    return 0
}

# Main execution
if is_mustgather; then
    analyze_servicemesh_mustgather
    result=$?
else
    analyze_servicemesh_live
    result=$?
fi

if [[ ${result} -eq 0 ]]; then
    exit "${RC_OKAY}"
else
    exit "${RC_FAILED}"
fi
