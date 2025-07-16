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

# long_name: OpenShift Secrets Management Validation Check
# description: Validates secrets, certificates, and security configurations in OpenShift
# priority: 800

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

is_required_file "${RISU_BASE}/common-functions.sh"

# Function to check if we're analyzing a Must Gather
is_mustgather() {
    [[ ${RISU_LIVE} != "1" ]] && [[ -d "namespaces" || -d "cluster-scoped-resources" ]]
}

# Function to analyze secrets from Must Gather
analyze_secrets_mustgather() {
    local secrets_issues=()

    # Check for secrets across namespaces
    local secret_issues=()
    local large_secrets=()

    if [[ -d "namespaces" ]]; then
        for ns_dir in namespaces/*; do
            if [[ -d ${ns_dir} ]]; then
                local namespace=$(basename "${ns_dir}")
                local secrets_file="${ns_dir}/core/secrets.yaml"

                if [[ -f ${secrets_file} ]]; then
                    local secret_count
                    secret_count=$(grep -c "^[[:space:]]*name:" "${secrets_file}" 2>/dev/null || echo 0)

                    if [[ ${secret_count} -gt 50 ]]; then
                        secret_issues+=("${namespace}: ${secret_count} secrets")
                    fi

                    # Check for TLS secrets
                    local tls_secrets
                    tls_secrets=$(grep -c "type:[[:space:]]*kubernetes.io/tls" "${secrets_file}" 2>/dev/null || echo 0)

                    if [[ ${tls_secrets} -gt 0 ]]; then
                        # Check for certificate data (simplified check)
                        local cert_data_count
                        cert_data_count=$(grep -c "tls.crt:" "${secrets_file}" 2>/dev/null || echo 0)

                        if [[ ${cert_data_count} -ne ${tls_secrets} ]]; then
                            secret_issues+=("${namespace}: TLS secrets without certificate data")
                        fi
                    fi

                    # Check for service account tokens
                    local sa_token_count
                    sa_token_count=$(grep -c "type:[[:space:]]*kubernetes.io/service-account-token" "${secrets_file}" 2>/dev/null || echo 0)

                    if [[ ${sa_token_count} -gt 20 ]]; then
                        secret_issues+=("${namespace}: Many service account tokens: ${sa_token_count}")
                    fi
                fi
            fi
        done
    fi

    if [[ ${#secret_issues[@]} -gt 0 ]]; then
        secrets_issues+=("Secret management issues: ${secret_issues[*]}")
    fi

    # Check for ConfigMaps with sensitive data
    local configmap_issues=()
    if [[ -d "namespaces" ]]; then
        for ns_dir in namespaces/*; do
            if [[ -d ${ns_dir} ]]; then
                local namespace=$(basename "${ns_dir}")
                local configmaps_file="${ns_dir}/core/configmaps.yaml"

                if [[ -f ${configmaps_file} ]]; then
                    # Check for potential sensitive data in ConfigMaps
                    local sensitive_data
                    sensitive_data=$(grep -c -i "password\|secret\|key\|token" "${configmaps_file}" 2>/dev/null || echo 0)

                    if [[ ${sensitive_data} -gt 0 ]]; then
                        configmap_issues+=("${namespace}: ConfigMaps with potential sensitive data")
                    fi
                fi
            fi
        done
    fi

    if [[ ${#configmap_issues[@]} -gt 0 ]]; then
        secrets_issues+=("ConfigMap security issues: ${configmap_issues[*]}")
    fi

    # Check for external secrets operator
    local external_secrets_found=false
    if [[ -d "namespaces" ]]; then
        for ns_dir in namespaces/*; do
            if [[ -d ${ns_dir} ]]; then
                local namespace=$(basename "${ns_dir}")
                local pods_file="${ns_dir}/core/pods.yaml"

                if [[ -f ${pods_file} ]]; then
                    if grep -q "external-secrets" "${pods_file}"; then
                        external_secrets_found=true
                        break
                    fi
                fi
            fi
        done
    fi

    if [[ ${external_secrets_found} == false ]]; then
        secrets_issues+=("No external secrets operator found")
    fi

    # Check for sealed secrets
    local sealed_secrets_found=false
    if [[ -d "namespaces" ]]; then
        for ns_dir in namespaces/*; do
            if [[ -d ${ns_dir} ]]; then
                local namespace=$(basename "${ns_dir}")
                local pods_file="${ns_dir}/core/pods.yaml"

                if [[ -f ${pods_file} ]]; then
                    if grep -q "sealed-secrets" "${pods_file}"; then
                        sealed_secrets_found=true
                        break
                    fi
                fi
            fi
        done
    fi

    if [[ ${sealed_secrets_found} == false ]]; then
        secrets_issues+=("No sealed secrets controller found")
    fi

    # Check for cert-manager
    local cert_manager_found=false
    if [[ -d "namespaces" ]]; then
        for ns_dir in namespaces/*; do
            if [[ -d ${ns_dir} ]]; then
                local namespace=$(basename "${ns_dir}")
                local pods_file="${ns_dir}/core/pods.yaml"

                if [[ -f ${pods_file} ]]; then
                    if grep -q "cert-manager" "${pods_file}"; then
                        cert_manager_found=true
                        break
                    fi
                fi
            fi
        done
    fi

    if [[ ${cert_manager_found} == false ]]; then
        secrets_issues+=("No cert-manager found")
    fi

    # Check for default pull secrets
    local pull_secret_issues=()
    if [[ -d "namespaces" ]]; then
        for ns_dir in namespaces/*; do
            if [[ -d ${ns_dir} ]]; then
                local namespace=$(basename "${ns_dir}")
                local secrets_file="${ns_dir}/core/secrets.yaml"

                if [[ -f ${secrets_file} ]]; then
                    local pull_secrets
                    pull_secrets=$(grep -c "type:[[:space:]]*kubernetes.io/dockerconfigjson" "${secrets_file}" 2>/dev/null || echo 0)

                    if [[ ${pull_secrets} -eq 0 ]]; then
                        pull_secret_issues+=("${namespace}")
                    fi
                fi
            fi
        done
    fi

    if [[ ${#pull_secret_issues[@]} -gt 10 ]]; then
        secrets_issues+=("Many namespaces without pull secrets: ${#pull_secret_issues[@]} namespaces")
    fi

    # Report findings
    if [[ ${#secrets_issues[@]} -gt 0 ]]; then
        echo "Secrets management issues found:" >&2
        printf '%s\n' "${secrets_issues[@]}" >&2
        exit ${RC_SKIPPED}
    fi

    return 0
}

# Function to analyze secrets from live cluster
analyze_secrets_live() {
    if ! command -v oc >/dev/null 2>&1; then
        echo "oc command not found" >&2
        exit ${RC_SKIPPED}
    fi

    # Check if we can connect to cluster
    if ! oc whoami >/dev/null 2>&1; then
        echo "Cannot connect to OpenShift cluster" >&2
        exit ${RC_SKIPPED}
    fi

    local secrets_issues=()

    # Check for secrets across namespaces
    local secret_issues
    secret_issues=$(oc get secrets --all-namespaces --no-headers 2>/dev/null | awk '{print $1}' | sort | uniq -c | sort -nr | head -5 | awk '$1 > 50 {print $2": "$1" secrets"}')

    if [[ -n ${secret_issues} ]]; then
        secrets_issues+=("Namespaces with many secrets: ${secret_issues}")
    fi

    # Check for TLS secrets
    local tls_secrets_count
    tls_secrets_count=$(oc get secrets --all-namespaces --no-headers 2>/dev/null | grep -c "kubernetes.io/tls")

    if [[ ${tls_secrets_count} -eq 0 ]]; then
        secrets_issues+=("No TLS secrets found")
    fi

    # Check for service account tokens
    local sa_token_issues
    sa_token_issues=$(oc get secrets --all-namespaces --no-headers 2>/dev/null | grep "service-account-token" | awk '{print $1}' | sort | uniq -c | sort -nr | head -3 | awk '$1 > 20 {print $2": "$1" tokens"}')

    if [[ -n ${sa_token_issues} ]]; then
        secrets_issues+=("Namespaces with many service account tokens: ${sa_token_issues}")
    fi

    # Check for ConfigMaps with sensitive data
    local configmap_issues
    configmap_issues=$(oc get configmaps --all-namespaces -o json 2/dev/null | jq -r '.items[] | select(.data != null) | select(.data | to_entries[] | .key | test("password|secret|key|token"; "i")) | .metadata.namespace + "/" + .metadata.name' 2>/dev/null | wc -l)

    if [[ ${configmap_issues} -gt 0 ]]; then
        secrets_issues+=("ConfigMaps with potential sensitive data: ${configmap_issues}")
    fi

    # Check for external secrets operator
    local external_secrets_count
    external_secrets_count=$(oc get pods --all-namespaces --no-headers 2>/dev/null | grep -c "external-secrets")

    if [[ ${external_secrets_count} -eq 0 ]]; then
        secrets_issues+=("No external secrets operator found")
    fi

    # Check for sealed secrets
    local sealed_secrets_count
    sealed_secrets_count=$(oc get pods --all-namespaces --no-headers 2>/dev/null | grep -c "sealed-secrets")

    if [[ ${sealed_secrets_count} -eq 0 ]]; then
        secrets_issues+=("No sealed secrets controller found")
    fi

    # Check for cert-manager
    local cert_manager_count
    cert_manager_count=$(oc get pods --all-namespaces --no-headers 2>/dev/null | grep -c "cert-manager")

    if [[ ${cert_manager_count} -eq 0 ]]; then
        secrets_issues+=("No cert-manager found")
    fi

    # Check for default pull secrets
    local pull_secret_issues
    pull_secret_issues=$(oc get namespaces --no-headers 2>/dev/null | while read -r ns _; do
        if [[ $(oc get secrets -n "${ns}" --no-headers 2>/dev/null | grep -c "kubernetes.io/dockerconfigjson") -eq 0 ]]; then
            echo "${ns}" >&2
        fi
    done | wc -l)

    if [[ ${pull_secret_issues} -gt 10 ]]; then
        secrets_issues+=("Many namespaces without pull secrets: ${pull_secret_issues} namespaces")
    fi

    # Check for certificates expiration
    local cert_expiry_issues
    cert_expiry_issues=$(oc get secrets --all-namespaces --no-headers 2>/dev/null | grep "kubernetes.io/tls" | head -10 | awk '{print $1"/"$2}')

    if [[ -n ${cert_expiry_issues} ]]; then
        secrets_issues+=("TLS certificates to check for expiration: ${cert_expiry_issues}")
    fi

    # Check for image pull secrets
    local global_pull_secret
    global_pull_secret=$(oc get secret pull-secret -n openshift-config --no-headers 2>/dev/null | wc -l)

    if [[ ${global_pull_secret} -eq 0 ]]; then
        secrets_issues+=("No global pull secret found")
    fi

    # Check for OAuth tokens
    local oauth_tokens_count
    oauth_tokens_count=$(oc get oauthaccesstokens --no-headers 2>/dev/null | wc -l)

    if [[ ${oauth_tokens_count} -eq 0 ]]; then
        secrets_issues+=("No OAuth access tokens found")
    fi

    # Check for webhook secrets
    local webhook_secrets
    webhook_secrets=$(oc get secrets --all-namespaces --no-headers 2>/dev/null | grep -c "webhook")

    if [[ ${webhook_secrets} -eq 0 ]]; then
        secrets_issues+=("No webhook secrets found")
    fi

    # Check for LDAP bind secrets
    local ldap_secrets
    ldap_secrets=$(oc get secrets --all-namespaces --no-headers 2>/dev/null | grep -c "ldap")

    if [[ ${ldap_secrets} -eq 0 ]]; then
        secrets_issues+=("No LDAP secrets found")
    fi

    # Check for secrets without owner references
    local orphaned_secrets
    orphaned_secrets=$(oc get secrets --all-namespaces -o json 2>/dev/null | jq -r '.items[] | select(.metadata.ownerReferences == null and .type != "kubernetes.io/service-account-token") | .metadata.namespace + "/" + .metadata.name' 2>/dev/null | wc -l)

    if [[ ${orphaned_secrets} -gt 20 ]]; then
        secrets_issues+=("Many orphaned secrets: ${orphaned_secrets}")
    fi

    # Check for secrets with large data
    local large_secrets
    large_secrets=$(oc get secrets --all-namespaces -o json 2>/dev/null | jq -r '.items[] | select(.data != null) | select(.data | to_entries | map(.value | length) | add > 1000000) | .metadata.namespace + "/" + .metadata.name' 2>/dev/null | wc -l)

    if [[ ${large_secrets} -gt 0 ]]; then
        secrets_issues+=("Large secrets found: ${large_secrets}")
    fi

    # Report findings
    if [[ ${#secrets_issues[@]} -gt 0 ]]; then
        echo "Secrets management issues found:" >&2
        printf '%s\n' "${secrets_issues[@]}" >&2
        exit ${RC_SKIPPED}
    fi

    return 0
}

# Main execution
if is_mustgather; then
    analyze_secrets_mustgather
    result=$?
else
    analyze_secrets_live
    result=$?
fi

if [[ ${result} -eq 0 ]]; then
    exit "${RC_OKAY}"
else
    exit "${RC_FAILED}"
fi
