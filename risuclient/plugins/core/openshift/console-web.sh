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

# long_name: OpenShift Console and Web Console Health Check
# description: Checks OpenShift web console configuration and access
# priority: 740

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

is_required_file "${RISU_BASE}/common-functions.sh"

# Function to check if we're analyzing a Must Gather
is_mustgather() {
    [[ ${RISU_LIVE} != "1" ]] && [[ -d "namespaces" || -d "cluster-scoped-resources" ]]
}

# Function to analyze console from Must Gather
analyze_console_mustgather() {
    local console_issues=()

    # Check console operator
    local console_co_file="cluster-scoped-resources/config.openshift.io/clusteroperators.yaml"
    if [[ -f ${console_co_file} ]]; then
        local in_console_operator=false
        local console_available=""
        local console_degraded=""

        while IFS= read -r line; do
            if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*console$ ]]; then
                in_console_operator=true
            elif [[ ${in_console_operator} == true ]] && [[ ${line} =~ ^[[:space:]]*type:[[:space:]]*Available$ ]]; then
                reading_available=true
            elif [[ ${in_console_operator} == true ]] && [[ ${line} =~ ^[[:space:]]*type:[[:space:]]*Degraded$ ]]; then
                reading_degraded=true
            elif [[ ${reading_available} == true ]] && [[ ${line} =~ ^[[:space:]]*status:[[:space:]]*(.+)$ ]]; then
                console_available="${BASH_REMATCH[1]}"
                reading_available=false
            elif [[ ${reading_degraded} == true ]] && [[ ${line} =~ ^[[:space:]]*status:[[:space:]]*(.+)$ ]]; then
                console_degraded="${BASH_REMATCH[1]}"
                reading_degraded=false
                break
            fi
        done <"${console_co_file}"

        if [[ ${console_available} != "True" ]]; then
            console_issues+=("Console operator not available: ${console_available}")
        fi

        if [[ ${console_degraded} == "True" ]]; then
            console_issues+=("Console operator degraded: ${console_degraded}")
        fi
    fi

    # Check console pods
    local console_ns_dir="namespaces/openshift-console"
    if [[ -d ${console_ns_dir} ]]; then
        local pods_file="${console_ns_dir}/core/pods.yaml"
        if [[ -f ${pods_file} ]]; then
            local failed_console_pods=()
            local current_pod=""
            local pod_phase=""

            while IFS= read -r line; do
                if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*(.+)$ ]]; then
                    current_pod="${BASH_REMATCH[1]}"
                elif [[ ${line} =~ ^[[:space:]]*phase:[[:space:]]*(.+)$ ]]; then
                    pod_phase="${BASH_REMATCH[1]}"

                    if [[ ${current_pod} =~ (console|downloads) ]]; then
                        if [[ ${pod_phase} != "Running" ]]; then
                            failed_console_pods+=("${current_pod}: ${pod_phase}")
                        fi
                    fi
                fi
            done <"${pods_file}"

            if [[ ${#failed_console_pods[@]} -gt 0 ]]; then
                console_issues+=("Failed console pods: ${failed_console_pods[*]}")
            fi
        fi
    fi

    # Check console operator pods
    local console_operator_ns_dir="namespaces/openshift-console-operator"
    if [[ -d ${console_operator_ns_dir} ]]; then
        local pods_file="${console_operator_ns_dir}/core/pods.yaml"
        if [[ -f ${pods_file} ]]; then
            local failed_operator_pods=()
            local current_pod=""
            local pod_phase=""

            while IFS= read -r line; do
                if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*(.+)$ ]]; then
                    current_pod="${BASH_REMATCH[1]}"
                elif [[ ${line} =~ ^[[:space:]]*phase:[[:space:]]*(.+)$ ]]; then
                    pod_phase="${BASH_REMATCH[1]}"

                    if [[ ${current_pod} =~ console-operator ]]; then
                        if [[ ${pod_phase} != "Running" ]]; then
                            failed_operator_pods+=("${current_pod}: ${pod_phase}")
                        fi
                    fi
                fi
            done <"${pods_file}"

            if [[ ${#failed_operator_pods[@]} -gt 0 ]]; then
                console_issues+=("Failed console operator pods: ${failed_operator_pods[*]}")
            fi
        fi
    fi

    # Check console routes
    local console_ns_dir="namespaces/openshift-console"
    if [[ -d ${console_ns_dir} ]]; then
        local routes_file="${console_ns_dir}/route.openshift.io/routes.yaml"
        if [[ -f ${routes_file} ]]; then
            local console_route_count
            console_route_count=$(grep -c "^[[:space:]]*name:[[:space:]]*console" "${routes_file}" 2>/dev/null || echo 0)

            if [[ ${console_route_count} -eq 0 ]]; then
                console_issues+=("No console route found")
            fi
        fi
    fi

    # Check console configuration
    local console_config_file="cluster-scoped-resources/operator.openshift.io/consoles.yaml"
    if [[ -f ${console_config_file} ]]; then
        local console_state=""

        while IFS= read -r line; do
            if [[ ${line} =~ ^[[:space:]]*managementState:[[:space:]]*(.+)$ ]]; then
                console_state="${BASH_REMATCH[1]}"
                break
            fi
        done <"${console_config_file}"

        if [[ ${console_state} == "Removed" ]]; then
            console_issues+=("Console is disabled/removed")
        fi
    fi

    # Check console services
    local console_ns_dir="namespaces/openshift-console"
    if [[ -d ${console_ns_dir} ]]; then
        local services_file="${console_ns_dir}/core/services.yaml"
        if [[ -f ${services_file} ]]; then
            local console_service_count
            console_service_count=$(grep -c "^[[:space:]]*name:[[:space:]]*console" "${services_file}" 2>/dev/null || echo 0)

            if [[ ${console_service_count} -eq 0 ]]; then
                console_issues+=("No console service found")
            fi
        fi
    fi

    # Check for console plugins
    local console_plugins_file="cluster-scoped-resources/console.openshift.io/consoleplugins.yaml"
    if [[ -f ${console_plugins_file} ]]; then
        local plugin_count
        plugin_count=$(grep -c "^[[:space:]]*name:" "${console_plugins_file}" 2>/dev/null || echo 0)

        if [[ ${plugin_count} -eq 0 ]]; then
            console_issues+=("No console plugins found")
        fi
    fi

    # Report findings
    if [[ ${#console_issues[@]} -gt 0 ]]; then
        echo "Console issues found:" >&2
        printf '%s\n' "${console_issues[@]}" >&2
        exit ${RC_SKIPPED}
    fi

    return 0
}

# Function to analyze console from live cluster
analyze_console_live() {
    if ! command -v oc >/dev/null 2>&1; then
        echo "oc command not found" >&2
        exit ${RC_SKIPPED}
    fi

    # Check if we can connect to cluster
    if ! oc whoami >/dev/null 2>&1; then
        echo "Cannot connect to OpenShift cluster" >&2
        exit ${RC_SKIPPED}
    fi

    local console_issues=()

    # Check console operator
    local console_operator_status
    console_operator_status=$(oc get clusteroperator console --no-headers 2>/dev/null | awk '{print $2" "$3" "$4}')

    if [[ ${console_operator_status} != "True False False" ]]; then
        console_issues+=("Console operator not healthy: ${console_operator_status}")
    fi

    # Check console pods
    local failed_console_pods
    failed_console_pods=$(oc get pods -n openshift-console --no-headers 2>/dev/null | grep -E "(console|downloads)" | grep -v "Running" | awk '{print $1": "$3}')

    if [[ -n ${failed_console_pods} ]]; then
        console_issues+=("Failed console pods: ${failed_console_pods}")
    fi

    # Check console operator pods
    local failed_operator_pods
    failed_operator_pods=$(oc get pods -n openshift-console-operator --no-headers 2>/dev/null | grep console-operator | grep -v "Running" | awk '{print $1": "$3}')

    if [[ -n ${failed_operator_pods} ]]; then
        console_issues+=("Failed console operator pods: ${failed_operator_pods}")
    fi

    # Check console routes
    local console_route_count
    console_route_count=$(oc get routes -n openshift-console --no-headers 2>/dev/null | grep -c "console")

    if [[ ${console_route_count} -eq 0 ]]; then
        console_issues+=("No console route found")
    fi

    # Check console configuration
    local console_config
    console_config=$(oc get console.operator.openshift.io cluster -o json 2>/dev/null)

    if [[ -n ${console_config} ]]; then
        local console_state
        console_state=$(echo "${console_config}" | jq -r '.spec.managementState' 2>/dev/null)

        if [[ ${console_state} == "Removed" ]]; then
            console_issues+=("Console is disabled/removed")
        fi
    fi

    # Check console services
    local console_service_count
    console_service_count=$(oc get services -n openshift-console --no-headers 2>/dev/null | grep -c "console")

    if [[ ${console_service_count} -eq 0 ]]; then
        console_issues+=("No console service found")
    fi

    # Check console accessibility
    local console_route
    console_route=$(oc get route console -n openshift-console --no-headers 2>/dev/null | awk '{print $2}')

    if [[ -n ${console_route} ]]; then
        # Try to check if console is accessible (basic check)
        if ! curl -k -s "https://${console_route}/health" >/dev/null 2>&1; then
            console_issues+=("Console not accessible via route")
        fi
    fi

    # Check for console plugins
    local console_plugin_count
    console_plugin_count=$(oc get consoleplugin --no-headers 2>/dev/null | wc -l)

    if [[ ${console_plugin_count} -eq 0 ]]; then
        console_issues+=("No console plugins found")
    fi

    # Check console logs for errors
    local console_log_errors
    console_log_errors=$(oc logs -n openshift-console deployment/console --tail=100 2>/dev/null | grep -i error | wc -l)

    if [[ ${console_log_errors} -gt 10 ]]; then
        console_issues+=("Many errors in console logs: ${console_log_errors} errors")
    fi

    # Check console operator logs for errors
    local operator_log_errors
    operator_log_errors=$(oc logs -n openshift-console-operator deployment/console-operator --tail=100 2>/dev/null | grep -i error | wc -l)

    if [[ ${operator_log_errors} -gt 10 ]]; then
        console_issues+=("Many errors in console operator logs: ${operator_log_errors} errors")
    fi

    # Check console authentication
    local console_auth_config
    console_auth_config=$(oc get oauth cluster -o json 2>/dev/null | jq -r '.spec.identityProviders | length' 2>/dev/null)

    if [[ ${console_auth_config} -eq 0 ]]; then
        console_issues+=("No identity providers configured for console authentication")
    fi

    # Check for console customizations
    local console_customizations
    console_customizations=$(oc get consolelink --no-headers 2>/dev/null | wc -l)

    if [[ ${console_customizations} -eq 0 ]]; then
        console_issues+=("No console customizations found")
    fi

    # Check for console notifications
    local console_notifications
    console_notifications=$(oc get consolenotification --no-headers 2>/dev/null | wc -l)

    if [[ ${console_notifications} -eq 0 ]]; then
        console_issues+=("No console notifications configured")
    fi

    # Check downloads service for CLI tools
    local downloads_service_count
    downloads_service_count=$(oc get services -n openshift-console --no-headers 2>/dev/null | grep -c "downloads")

    if [[ ${downloads_service_count} -eq 0 ]]; then
        console_issues+=("No downloads service found for CLI tools")
    fi

    # Report findings
    if [[ ${#console_issues[@]} -gt 0 ]]; then
        echo "Console issues found:" >&2
        printf '%s\n' "${console_issues[@]}" >&2
        exit ${RC_SKIPPED}
    fi

    return 0
}

# Main execution
if is_mustgather; then
    analyze_console_mustgather
    result=$?
else
    analyze_console_live
    result=$?
fi

if [[ ${result} -eq 0 ]]; then
    exit "${RC_OKAY}"
else
    exit "${RC_FAILED}"
fi
