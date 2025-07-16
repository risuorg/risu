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

# long_name: OpenShift Operator Health Check
# description: OpenShift Operator Health validation and monitoring
# priority: 740
# Validates OpenShift operators health and subscription status

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

is_required_file "${RISU_BASE}/common-functions.sh"

# Function to check if we're analyzing a Must Gather
is_mustgather() {
    [[ ${RISU_LIVE} != "1" ]] && [[ -d "namespaces" || -d "cluster-scoped-resources" ]]
}

# Function to analyze operators from Must Gather
analyze_operators_mustgather() {
    local failed_operators=()
    local degraded_operators=()
    local subscription_issues=()

    # Check cluster operators
    local co_file="cluster-scoped-resources/config.openshift.io/clusteroperators.yaml"
    if [[ -f ${co_file} ]]; then
        local current_operator=""
        local operator_available="Unknown"
        local operator_progressing="Unknown"
        local operator_degraded="Unknown"

        while IFS= read -r line; do
            if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*(.+)$ ]]; then
                current_operator="${BASH_REMATCH[1]}"
                operator_available="Unknown"
                operator_progressing="Unknown"
                operator_degraded="Unknown"
            elif [[ ${line} =~ ^[[:space:]]*type:[[:space:]]*Available$ ]]; then
                reading_available=true
            elif [[ ${line} =~ ^[[:space:]]*type:[[:space:]]*Progressing$ ]]; then
                reading_progressing=true
            elif [[ ${line} =~ ^[[:space:]]*type:[[:space:]]*Degraded$ ]]; then
                reading_degraded=true
            elif [[ ${reading_available} == true ]] && [[ ${line} =~ ^[[:space:]]*status:[[:space:]]*(.+)$ ]]; then
                operator_available="${BASH_REMATCH[1]}"
                reading_available=false
            elif [[ ${reading_progressing} == true ]] && [[ ${line} =~ ^[[:space:]]*status:[[:space:]]*(.+)$ ]]; then
                operator_progressing="${BASH_REMATCH[1]}"
                reading_progressing=false
            elif [[ ${reading_degraded} == true ]] && [[ ${line} =~ ^[[:space:]]*status:[[:space:]]*(.+)$ ]]; then
                operator_degraded="${BASH_REMATCH[1]}"
                reading_degraded=false

                # Check if operator has issues
                if [[ ${operator_available} != "True" ]]; then
                    failed_operators+=("${current_operator}: Available=${operator_available}")
                fi
                if [[ ${operator_degraded} == "True" ]]; then
                    degraded_operators+=("${current_operator}: Degraded=${operator_degraded}")
                fi
            fi
        done <"${co_file}"
    fi

    # Check OLM subscriptions
    for ns_dir in namespaces/*; do
        if [[ -d ${ns_dir} ]]; then
            local namespace=$(basename "${ns_dir}")
            local subs_file="${ns_dir}/operators.coreos.com/subscriptions.yaml"

            if [[ -f ${subs_file} ]]; then
                local current_subscription=""
                local sub_state=""

                while IFS= read -r line; do
                    if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*(.+)$ ]]; then
                        current_subscription="${BASH_REMATCH[1]}"
                    elif [[ ${line} =~ ^[[:space:]]*state:[[:space:]]*(.+)$ ]]; then
                        sub_state="${BASH_REMATCH[1]}"

                        if [[ ${sub_state} != "AtLatestKnown" ]]; then
                            subscription_issues+=("${namespace}/${current_subscription}: ${sub_state}")
                        fi
                    fi
                done <"${subs_file}"
            fi
        fi
    done

    # Report findings
    local issues_found=false

    if [[ ${#failed_operators[@]} -gt 0 ]]; then
        echo "Cluster operators not available:" >&2
        printf '%s\n' "${failed_operators[@]}" >&2
        issues_found=true
    fi

    if [[ ${#degraded_operators[@]} -gt 0 ]]; then
        echo "Degraded cluster operators:" >&2
        printf '%s\n' "${degraded_operators[@]}" >&2
        issues_found=true
    fi

    if [[ ${#subscription_issues[@]} -gt 0 ]]; then
        echo "Subscription issues:" >&2
        printf '%s\n' "${subscription_issues[@]}" >&2
        issues_found=true
    fi

    if [[ ${issues_found} == true ]]; then
        exit ${RC_SKIPPED}
    fi

    return 0
}

# Function to analyze operators from live cluster
analyze_operators_live() {
    if ! command -v oc >/dev/null 2>&1; then
        echo "oc command not found" >&2
        exit ${RC_SKIPPED}
    fi

    # Check if we can connect to cluster
    if ! oc whoami >/dev/null 2>&1; then
        echo "Cannot connect to OpenShift cluster" >&2
        exit ${RC_SKIPPED}
    fi

    local issues_found=false

    # Check cluster operators
    local failed_operators
    failed_operators=$(oc get clusteroperators --no-headers | grep -v "True.*False.*False" | awk '{print $1": Available="$2" Progressing="$3" Degraded="$4}')

    if [[ -n ${failed_operators} ]]; then
        echo "Cluster operators with issues:" >&2
        echo "${failed_operators}" >&2
        issues_found=true
    fi

    # Check OLM subscriptions
    local subscription_issues
    subscription_issues=$(oc get subscriptions --all-namespaces --no-headers | grep -v "AtLatestKnown" | awk '{print $1"/"$2": "$4}')

    if [[ -n ${subscription_issues} ]]; then
        echo "Subscription issues:" >&2
        echo "${subscription_issues}" >&2
        issues_found=true
    fi

    # Check for failed InstallPlans
    local failed_installplans
    failed_installplans=$(oc get installplans --all-namespaces --no-headers | grep -v "Complete" | awk '{print $1"/"$2": "$3}')

    if [[ -n ${failed_installplans} ]]; then
        echo "Failed InstallPlans:" >&2
        echo "${failed_installplans}" >&2
        issues_found=true
    fi

    if [[ ${issues_found} == true ]]; then
        exit ${RC_SKIPPED}
    fi

    return 0
}

# Main execution
if is_mustgather; then
    analyze_operators_mustgather
    result=$?
else
    analyze_operators_live
    result=$?
fi

if [[ ${result} -eq 0 ]]; then
    exit "${RC_OKAY}"
else
    exit "${RC_FAILED}"
fi
