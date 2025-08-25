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

# long_name: OpenShift Authentication and Authorization Health Check
# description: Checks OpenShift authentication configuration and security
# priority: 800

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

is_required_file "${RISU_BASE}/common-functions.sh"

# Function to check if we're analyzing a Must Gather
is_mustgather() {
    [[ ${RISU_LIVE} != "1" ]] && [[ -d "namespaces" || -d "cluster-scoped-resources" ]]
}

# Function to analyze authentication from Must Gather
analyze_auth_mustgather() {
    local auth_issues=()

    # Check authentication operator
    local auth_co_file="cluster-scoped-resources/config.openshift.io/clusteroperators.yaml"
    if [[ -f ${auth_co_file} ]]; then
        local in_auth_operator=false
        local auth_available=""
        local auth_degraded=""

        while IFS= read -r line; do
            if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*authentication$ ]]; then
                in_auth_operator=true
            elif [[ ${in_auth_operator} == true ]] && [[ ${line} =~ ^[[:space:]]*type:[[:space:]]*Available$ ]]; then
                reading_available=true
            elif [[ ${in_auth_operator} == true ]] && [[ ${line} =~ ^[[:space:]]*type:[[:space:]]*Degraded$ ]]; then
                reading_degraded=true
            elif [[ ${reading_available} == true ]] && [[ ${line} =~ ^[[:space:]]*status:[[:space:]]*(.+)$ ]]; then
                auth_available="${BASH_REMATCH[1]}"
                reading_available=false
            elif [[ ${reading_degraded} == true ]] && [[ ${line} =~ ^[[:space:]]*status:[[:space:]]*(.+)$ ]]; then
                auth_degraded="${BASH_REMATCH[1]}"
                reading_degraded=false
                break
            fi
        done <"${auth_co_file}"

        if [[ ${auth_available} != "True" ]]; then
            auth_issues+=("Authentication operator not available: ${auth_available}")
        fi

        if [[ ${auth_degraded} == "True" ]]; then
            auth_issues+=("Authentication operator degraded: ${auth_degraded}")
        fi
    fi

    # Check OAuth configuration
    local oauth_file="cluster-scoped-resources/config.openshift.io/oauths.yaml"
    if [[ -f ${oauth_file} ]]; then
        local identity_providers_count
        identity_providers_count=$(grep -c "identityProviders:" "${oauth_file}" 2>/dev/null || echo 0)

        if [[ ${identity_providers_count} -eq 0 ]]; then
            auth_issues+=("No identity providers configured")
        fi
    fi

    # Check OAuth pods
    local oauth_ns_dir="namespaces/openshift-authentication"
    if [[ -d ${oauth_ns_dir} ]]; then
        local pods_file="${oauth_ns_dir}/core/pods.yaml"
        if [[ -f ${pods_file} ]]; then
            local failed_oauth_pods=()
            local current_pod=""
            local pod_phase=""

            while IFS= read -r line; do
                if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*(.+)$ ]]; then
                    current_pod="${BASH_REMATCH[1]}"
                elif [[ ${line} =~ ^[[:space:]]*phase:[[:space:]]*(.+)$ ]]; then
                    pod_phase="${BASH_REMATCH[1]}"

                    if [[ ${current_pod} =~ (oauth-openshift|oauth-proxy) ]]; then
                        if [[ ${pod_phase} != "Running" ]]; then
                            failed_oauth_pods+=("${current_pod}: ${pod_phase}")
                        fi
                    fi
                fi
            done <"${pods_file}"

            if [[ ${#failed_oauth_pods[@]} -gt 0 ]]; then
                auth_issues+=("Failed OAuth pods: ${failed_oauth_pods[*]}")
            fi
        fi
    fi

    # Check for excessive ClusterRoleBindings
    local crb_file="cluster-scoped-resources/rbac.authorization.k8s.io/clusterrolebindings.yaml"
    if [[ -f ${crb_file} ]]; then
        local cluster_admin_bindings
        cluster_admin_bindings=$(grep -c "cluster-admin" "${crb_file}" 2>/dev/null || echo 0)

        if [[ ${cluster_admin_bindings} -gt 10 ]]; then
            auth_issues+=("Many cluster-admin bindings: ${cluster_admin_bindings}")
        fi
    fi

    # Check for service account tokens
    local sa_token_issues=()
    if [[ -d "namespaces" ]]; then
        for ns_dir in namespaces/*; do
            if [[ -d ${ns_dir} ]]; then
                local namespace=$(basename "${ns_dir}")
                local sa_file="${ns_dir}/core/serviceaccounts.yaml"

                if [[ -f ${sa_file} ]]; then
                    local sa_count
                    sa_count=$(grep -c "^[[:space:]]*name:" "${sa_file}" 2>/dev/null || echo 0)

                    if [[ ${sa_count} -gt 20 ]]; then
                        sa_token_issues+=("${namespace}: ${sa_count} service accounts")
                    fi
                fi
            fi
        done
    fi

    if [[ ${#sa_token_issues[@]} -gt 0 ]]; then
        auth_issues+=("Namespaces with many service accounts: ${sa_token_issues[*]}")
    fi

    # Check for users and groups
    local users_file="cluster-scoped-resources/user.openshift.io/users.yaml"
    if [[ -f ${users_file} ]]; then
        local users_count
        users_count=$(grep -c "^[[:space:]]*name:" "${users_file}" 2>/dev/null || echo 0)

        if [[ ${users_count} -eq 0 ]]; then
            auth_issues+=("No users found in cluster")
        fi
    fi

    # Check for OAuth tokens
    local oauth_ns_dir="namespaces/openshift-authentication"
    if [[ -d ${oauth_ns_dir} ]]; then
        local secrets_file="${oauth_ns_dir}/core/secrets.yaml"
        if [[ -f ${secrets_file} ]]; then
            local oauth_token_count
            oauth_token_count=$(grep -c "oauth-token" "${secrets_file}" 2>/dev/null || echo 0)

            if [[ ${oauth_token_count} -eq 0 ]]; then
                auth_issues+=("No OAuth tokens found")
            fi
        fi
    fi

    # Report findings
    if [[ ${#auth_issues[@]} -gt 0 ]]; then
        echo "Authentication and authorization issues found:" >&2
        printf '%s\n' "${auth_issues[@]}" >&2
        exit ${RC_SKIPPED}
    fi

    return 0
}

# Function to analyze authentication from live cluster
analyze_auth_live() {
    if ! command -v oc >/dev/null 2>&1; then
        echo "oc command not found" >&2
        exit ${RC_SKIPPED}
    fi

    # Check if we can connect to cluster
    if ! oc whoami >/dev/null 2>&1; then
        echo "Cannot connect to OpenShift cluster" >&2
        exit ${RC_SKIPPED}
    fi

    local auth_issues=()

    # Check authentication operator
    local auth_operator_status
    auth_operator_status=$(oc get clusteroperator authentication --no-headers 2>/dev/null | awk '{print $2" "$3" "$4}')

    if [[ ${auth_operator_status} != "True False False" ]]; then
        auth_issues+=("Authentication operator not healthy: ${auth_operator_status}")
    fi

    # Check OAuth configuration
    local oauth_config
    oauth_config=$(oc get oauth.config.openshift.io cluster -o json 2>/dev/null)

    if [[ -n ${oauth_config} ]]; then
        local identity_providers_count
        identity_providers_count=$(echo "${oauth_config}" | jq '.spec.identityProviders | length' 2>/dev/null)

        if [[ ${identity_providers_count} -eq 0 ]]; then
            auth_issues+=("No identity providers configured")
        fi
    fi

    # Check OAuth pods
    local failed_oauth_pods
    failed_oauth_pods=$(oc get pods -n openshift-authentication --no-headers 2>/dev/null | grep -E "(oauth-openshift|oauth-proxy)" | grep -v "Running" | awk '{print $1": "$3}')

    if [[ -n ${failed_oauth_pods} ]]; then
        auth_issues+=("Failed OAuth pods: ${failed_oauth_pods}")
    fi

    # Check for excessive ClusterRoleBindings
    local cluster_admin_bindings
    cluster_admin_bindings=$(oc get clusterrolebindings --no-headers 2>/dev/null | grep -c "cluster-admin")

    if [[ ${cluster_admin_bindings} -gt 10 ]]; then
        auth_issues+=("Many cluster-admin bindings: ${cluster_admin_bindings}")
    fi

    # Check for service account tokens
    local sa_token_issues
    sa_token_issues=$(oc get serviceaccounts --all-namespaces --no-headers 2>/dev/null | awk '{print $1}' | sort | uniq -c | sort -nr | head -3 | awk '$1 > 20 {print $2": "$1" service accounts"}')

    if [[ -n ${sa_token_issues} ]]; then
        auth_issues+=("Namespaces with many service accounts: ${sa_token_issues}")
    fi

    # Check for users and groups
    local users_count
    users_count=$(oc get users --no-headers 2>/dev/null | wc -l)

    if [[ ${users_count} -eq 0 ]]; then
        auth_issues+=("No users found in cluster")
    fi

    # Check for OAuth tokens
    local oauth_token_count
    oauth_token_count=$(oc get oauthaccesstokens --no-headers 2>/dev/null | wc -l)

    if [[ ${oauth_token_count} -eq 0 ]]; then
        auth_issues+=("No OAuth access tokens found")
    fi

    # Check for API server certificates
    local api_cert_issues
    api_cert_issues=$(oc get secrets -n openshift-config --no-headers 2>/dev/null | grep -c "serving-cert")

    if [[ ${api_cert_issues} -eq 0 ]]; then
        auth_issues+=("No API server certificates found")
    fi

    # Check for authentication logs
    local auth_log_errors
    auth_log_errors=$(oc logs -n openshift-authentication deployment/oauth-openshift --tail=100 2>/dev/null | grep -i error | wc -l)

    if [[ ${auth_log_errors} -gt 10 ]]; then
        auth_issues+=("Many errors in authentication logs: ${auth_log_errors} errors")
    fi

    # Check for role bindings without subjects
    local empty_rolebindings
    empty_rolebindings=$(oc get rolebindings --all-namespaces -o json 2>/dev/null | jq -r '.items[] | select(.subjects == null or .subjects == []) | .metadata.namespace + "/" + .metadata.name' 2>/dev/null | wc -l)

    if [[ ${empty_rolebindings} -gt 0 ]]; then
        auth_issues+=("Role bindings without subjects: ${empty_rolebindings}")
    fi

    # Check for RBAC authorization issues
    local rbac_denials
    rbac_denials=$(oc get events --all-namespaces --field-selector reason=FailedMount 2>/dev/null | grep -c "forbidden")

    if [[ ${rbac_denials} -gt 5 ]]; then
        auth_issues+=("RBAC authorization denials: ${rbac_denials}")
    fi

    # Check for webhook authenticators
    local webhook_auth_count
    webhook_auth_count=$(oc get validatingadmissionwebhook --no-headers 2>/dev/null | wc -l)

    if [[ ${webhook_auth_count} -eq 0 ]]; then
        auth_issues+=("No validating admission webhooks found")
    fi

    # Report findings
    if [[ ${#auth_issues[@]} -gt 0 ]]; then
        echo "Authentication and authorization issues found:" >&2
        printf '%s\n' "${auth_issues[@]}" >&2
        exit ${RC_SKIPPED}
    fi

    return 0
}

# Main execution
if is_mustgather; then
    analyze_auth_mustgather
    result=$?
else
    analyze_auth_live
    result=$?
fi

if [[ ${result} -eq 0 ]]; then
    exit "${RC_OKAY}"
else
    exit "${RC_FAILED}"
fi
