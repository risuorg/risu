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

# long_name: OpenShift Security and Compliance Check
# description: Checks OpenShift security compliance and policies
# priority: 810

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

is_required_file "${RISU_BASE}/common-functions.sh"

# Function to check if we're analyzing a Must Gather
is_mustgather() {
    [[ ${RISU_LIVE} != "1" ]] && [[ -d "namespaces" || -d "cluster-scoped-resources" ]]
}

# Function to analyze security from Must Gather
analyze_security_mustgather() {
    local security_issues=()

    # Check SecurityContextConstraints
    local scc_file="cluster-scoped-resources/security.openshift.io/securitycontextconstraints.yaml"
    if [[ -f ${scc_file} ]]; then
        local privileged_sccs=()
        local current_scc=""
        local scc_privileged=""

        while IFS= read -r line; do
            if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*(.+)$ ]]; then
                current_scc="${BASH_REMATCH[1]}"
            elif [[ ${line} =~ ^[[:space:]]*privileged:[[:space:]]*true$ ]]; then
                privileged_sccs+=("${current_scc}")
            fi
        done <"${scc_file}"

        if [[ ${#privileged_sccs[@]} -gt 2 ]]; then
            security_issues+=("Many privileged SCCs found: ${privileged_sccs[*]}")
        fi
    fi

    # Check for pods running as root
    local root_pods=()
    if [[ -d "namespaces" ]]; then
        for ns_dir in namespaces/*; do
            if [[ -d ${ns_dir} ]]; then
                local namespace=$(basename "${ns_dir}")
                local pods_file="${ns_dir}/core/pods.yaml"

                if [[ -f ${pods_file} ]]; then
                    local current_pod=""
                    local runs_as_root=false

                    while IFS= read -r line; do
                        if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*(.+)$ ]]; then
                            current_pod="${BASH_REMATCH[1]}"
                            runs_as_root=false
                        elif [[ ${line} =~ ^[[:space:]]*runAsUser:[[:space:]]*0$ ]]; then
                            runs_as_root=true
                        elif [[ ${line} =~ ^[[:space:]]*phase:[[:space:]]*Running$ ]]; then
                            if [[ ${runs_as_root} == true ]]; then
                                root_pods+=("${namespace}/${current_pod}")
                            fi
                        fi
                    done <"${pods_file}"
                fi
            fi
        done
    fi

    if [[ ${#root_pods[@]} -gt 0 ]]; then
        security_issues+=("Pods running as root: ${root_pods[*]}")
    fi

    # Check RBAC ClusterRoles with dangerous permissions
    local dangerous_clusterroles=()
    local cr_file="cluster-scoped-resources/rbac.authorization.k8s.io/clusterroles.yaml"
    if [[ -f ${cr_file} ]]; then
        local current_role=""
        local has_dangerous_perms=false

        while IFS= read -r line; do
            if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*(.+)$ ]]; then
                current_role="${BASH_REMATCH[1]}"
                has_dangerous_perms=false
            elif [[ ${line} =~ ^[[:space:]]*-[[:space:]]*\*$ ]]; then
                has_dangerous_perms=true
            elif [[ ${line} =~ ^[[:space:]]*resources:$ ]]; then
                checking_resources=true
            elif [[ ${checking_resources} == true ]] && [[ ${line} =~ ^[[:space:]]*-[[:space:]]*\*$ ]]; then
                has_dangerous_perms=true
                checking_resources=false
            elif [[ ${has_dangerous_perms} == true ]] && [[ ${line} =~ ^[[:space:]]*verbs:$ ]]; then
                dangerous_clusterroles+=("${current_role}")
                has_dangerous_perms=false
            fi
        done <"${cr_file}"

        if [[ ${#dangerous_clusterroles[@]} -gt 5 ]]; then
            security_issues+=("Many ClusterRoles with wildcard permissions: ${#dangerous_clusterroles[@]}")
        fi
    fi

    # Check for default service account usage
    local default_sa_pods=()
    if [[ -d "namespaces" ]]; then
        for ns_dir in namespaces/*; do
            if [[ -d ${ns_dir} ]]; then
                local namespace=$(basename "${ns_dir}")
                local pods_file="${ns_dir}/core/pods.yaml"

                if [[ -f ${pods_file} ]]; then
                    local current_pod=""
                    local service_account=""

                    while IFS= read -r line; do
                        if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*(.+)$ ]]; then
                            current_pod="${BASH_REMATCH[1]}"
                        elif [[ ${line} =~ ^[[:space:]]*serviceAccountName:[[:space:]]*default$ ]]; then
                            default_sa_pods+=("${namespace}/${current_pod}")
                        fi
                    done <"${pods_file}"
                fi
            fi
        done
    fi

    if [[ ${#default_sa_pods[@]} -gt 10 ]]; then
        security_issues+=("Many pods using default service account: ${#default_sa_pods[@]} pods")
    fi

    # Check for pods with privileged containers
    local privileged_pods=()
    if [[ -d "namespaces" ]]; then
        for ns_dir in namespaces/*; do
            if [[ -d ${ns_dir} ]]; then
                local namespace=$(basename "${ns_dir}")
                local pods_file="${ns_dir}/core/pods.yaml"

                if [[ -f ${pods_file} ]]; then
                    local current_pod=""
                    local is_privileged=false

                    while IFS= read -r line; do
                        if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*(.+)$ ]]; then
                            current_pod="${BASH_REMATCH[1]}"
                            is_privileged=false
                        elif [[ ${line} =~ ^[[:space:]]*privileged:[[:space:]]*true$ ]]; then
                            is_privileged=true
                        elif [[ ${line} =~ ^[[:space:]]*phase:[[:space:]]*Running$ ]]; then
                            if [[ ${is_privileged} == true ]]; then
                                privileged_pods+=("${namespace}/${current_pod}")
                            fi
                        fi
                    done <"${pods_file}"
                fi
            fi
        done
    fi

    if [[ ${#privileged_pods[@]} -gt 0 ]]; then
        security_issues+=("Privileged pods found: ${privileged_pods[*]}")
    fi

    # Check network policies
    local namespaces_without_netpol=()
    if [[ -d "namespaces" ]]; then
        for ns_dir in namespaces/*; do
            if [[ -d ${ns_dir} ]]; then
                local namespace=$(basename "${ns_dir}")
                local netpol_file="${ns_dir}/networking.k8s.io/networkpolicies.yaml"

                if [[ ! -f ${netpol_file} ]]; then
                    namespaces_without_netpol+=("${namespace}")
                fi
            fi
        done
    fi

    if [[ ${#namespaces_without_netpol[@]} -gt 5 ]]; then
        security_issues+=("Many namespaces without network policies: ${#namespaces_without_netpol[@]} namespaces")
    fi

    # Report findings
    if [[ ${#security_issues[@]} -gt 0 ]]; then
        echo "Security issues found:" >&2
        printf '%s\n' "${security_issues[@]}" >&2
        exit ${RC_SKIPPED}
    fi

    return 0
}

# Function to analyze security from live cluster
analyze_security_live() {
    if ! command -v oc >/dev/null 2>&1; then
        echo "oc command not found" >&2
        exit ${RC_SKIPPED}
    fi

    # Check if we can connect to cluster
    if ! oc whoami >/dev/null 2>&1; then
        echo "Cannot connect to OpenShift cluster" >&2
        exit ${RC_SKIPPED}
    fi

    local security_issues=()

    # Check SecurityContextConstraints
    local privileged_sccs
    privileged_sccs=$(oc get scc --no-headers 2>/dev/null | grep -c "privileged.*true")

    if [[ ${privileged_sccs} -gt 2 ]]; then
        security_issues+=("Many privileged SCCs found: ${privileged_sccs}")
    fi

    # Check for pods running as root
    local root_pods_count
    root_pods_count=$(oc get pods --all-namespaces -o json 2>/dev/null | jq '[.items[] | select(.spec.securityContext.runAsUser == 0 or .spec.containers[].securityContext.runAsUser == 0)] | length' 2>/dev/null || echo 0)

    if [[ ${root_pods_count} -gt 0 ]]; then
        security_issues+=("Pods running as root: ${root_pods_count} pods")
    fi

    # Check RBAC ClusterRoles with dangerous permissions
    local dangerous_clusterroles_count
    dangerous_clusterroles_count=$(oc get clusterroles -o json 2>/dev/null | jq '[.items[] | select(.rules[]? | select(.verbs[]? == "*" or .resources[]? == "*" or .apiGroups[]? == "*"))] | length' 2>/dev/null || echo 0)

    if [[ ${dangerous_clusterroles_count} -gt 5 ]]; then
        security_issues+=("Many ClusterRoles with wildcard permissions: ${dangerous_clusterroles_count}")
    fi

    # Check for default service account usage
    local default_sa_pods_count
    default_sa_pods_count=$(oc get pods --all-namespaces -o json 2>/dev/null | jq '[.items[] | select(.spec.serviceAccountName == "default")] | length' 2>/dev/null || echo 0)

    if [[ ${default_sa_pods_count} -gt 10 ]]; then
        security_issues+=("Many pods using default service account: ${default_sa_pods_count} pods")
    fi

    # Check for pods with privileged containers
    local privileged_pods_count
    privileged_pods_count=$(oc get pods --all-namespaces -o json 2>/dev/null | jq '[.items[] | select(.spec.containers[].securityContext.privileged == true)] | length' 2>/dev/null || echo 0)

    if [[ ${privileged_pods_count} -gt 0 ]]; then
        security_issues+=("Privileged pods found: ${privileged_pods_count} pods")
    fi

    # Check network policies
    local namespaces_without_netpol_count
    namespaces_without_netpol_count=$(oc get namespaces --no-headers 2>/dev/null | while read -r ns _; do
        if [[ $(oc get networkpolicies -n "${ns}" --no-headers 2>/dev/null | wc -l) -eq 0 ]]; then
            echo "${ns}" >&2
        fi
    done | wc -l)

    if [[ ${namespaces_without_netpol_count} -gt 5 ]]; then
        security_issues+=("Many namespaces without network policies: ${namespaces_without_netpol_count} namespaces")
    fi

    # Check for pods with host network
    local host_network_pods_count
    host_network_pods_count=$(oc get pods --all-namespaces -o json 2>/dev/null | jq '[.items[] | select(.spec.hostNetwork == true)] | length' 2>/dev/null || echo 0)

    if [[ ${host_network_pods_count} -gt 0 ]]; then
        security_issues+=("Pods with host network: ${host_network_pods_count} pods")
    fi

    # Check for pods with host PID
    local host_pid_pods_count
    host_pid_pods_count=$(oc get pods --all-namespaces -o json 2>/dev/null | jq '[.items[] | select(.spec.hostPID == true)] | length' 2>/dev/null || echo 0)

    if [[ ${host_pid_pods_count} -gt 0 ]]; then
        security_issues+=("Pods with host PID: ${host_pid_pods_count} pods")
    fi

    # Check for pods with host IPC
    local host_ipc_pods_count
    host_ipc_pods_count=$(oc get pods --all-namespaces -o json 2>/dev/null | jq '[.items[] | select(.spec.hostIPC == true)] | length' 2>/dev/null || echo 0)

    if [[ ${host_ipc_pods_count} -gt 0 ]]; then
        security_issues+=("Pods with host IPC: ${host_ipc_pods_count} pods")
    fi

    # Check certificate expiration
    local cert_expiry_issues
    cert_expiry_issues=$(oc get secrets --all-namespaces -o json 2>/dev/null | jq -r '.items[] | select(.type == "kubernetes.io/tls") | select(.data."tls.crt" != null) | .metadata.namespace + "/" + .metadata.name' 2>/dev/null | head -5)

    if [[ -n ${cert_expiry_issues} ]]; then
        security_issues+=("TLS certificates to check for expiration: ${cert_expiry_issues}")
    fi

    # Check for admission controllers
    local admission_controllers
    admission_controllers=$(oc get mutatingadmissionwebhook --no-headers 2>/dev/null | wc -l)

    if [[ ${admission_controllers} -eq 0 ]]; then
        security_issues+=("No mutating admission webhooks found")
    fi

    # Report findings
    if [[ ${#security_issues[@]} -gt 0 ]]; then
        echo "Security issues found:" >&2
        printf '%s\n' "${security_issues[@]}" >&2
        exit ${RC_SKIPPED}
    fi

    return 0
}

# Main execution
if is_mustgather; then
    analyze_security_mustgather
    result=$?
else
    analyze_security_live
    result=$?
fi

if [[ ${result} -eq 0 ]]; then
    exit "${RC_OKAY}"
else
    exit "${RC_FAILED}"
fi
