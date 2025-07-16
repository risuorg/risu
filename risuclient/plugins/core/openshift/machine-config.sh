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

# long_name: OpenShift Machine Configuration Health Check
# description: Checks OpenShift machine configuration and node setup
# priority: 900

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

is_required_file "${RISU_BASE}/common-functions.sh"

# Function to check if we're analyzing a Must Gather
is_mustgather() {
    [[ ${RISU_LIVE} != "1" ]] && [[ -d "namespaces" || -d "cluster-scoped-resources" ]]
}

# Function to analyze machine config from Must Gather
analyze_machineconfig_mustgather() {
    local machineconfig_issues=()

    # Check machine-config operator
    local mco_co_file="cluster-scoped-resources/config.openshift.io/clusteroperators.yaml"
    if [[ -f ${mco_co_file} ]]; then
        local in_mco_operator=false
        local mco_available=""
        local mco_degraded=""

        while IFS= read -r line; do
            if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*machine-config$ ]]; then
                in_mco_operator=true
            elif [[ ${in_mco_operator} == true ]] && [[ ${line} =~ ^[[:space:]]*type:[[:space:]]*Available$ ]]; then
                reading_available=true
            elif [[ ${in_mco_operator} == true ]] && [[ ${line} =~ ^[[:space:]]*type:[[:space:]]*Degraded$ ]]; then
                reading_degraded=true
            elif [[ ${reading_available} == true ]] && [[ ${line} =~ ^[[:space:]]*status:[[:space:]]*(.+)$ ]]; then
                mco_available="${BASH_REMATCH[1]}"
                reading_available=false
            elif [[ ${reading_degraded} == true ]] && [[ ${line} =~ ^[[:space:]]*status:[[:space:]]*(.+)$ ]]; then
                mco_degraded="${BASH_REMATCH[1]}"
                reading_degraded=false
                break
            fi
        done <"${mco_co_file}"

        if [[ ${mco_available} != "True" ]]; then
            machineconfig_issues+=("Machine-config operator not available: ${mco_available}")
        fi

        if [[ ${mco_degraded} == "True" ]]; then
            machineconfig_issues+=("Machine-config operator degraded: ${mco_degraded}")
        fi
    fi

    # Check MachineConfigPools
    local mcp_file="cluster-scoped-resources/machineconfiguration.openshift.io/machineconfigpools.yaml"
    if [[ -f ${mcp_file} ]]; then
        local degraded_mcps=()
        local current_mcp=""
        local mcp_conditions=""

        while IFS= read -r line; do
            if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*(.+)$ ]]; then
                current_mcp="${BASH_REMATCH[1]}"
            elif [[ ${line} =~ ^[[:space:]]*type:[[:space:]]*Degraded$ ]]; then
                reading_degraded=true
            elif [[ ${reading_degraded} == true ]] && [[ ${line} =~ ^[[:space:]]*status:[[:space:]]*True$ ]]; then
                degraded_mcps+=("${current_mcp}")
                reading_degraded=false
            elif [[ ${reading_degraded} == true ]] && [[ ${line} =~ ^[[:space:]]*status:[[:space:]]*False$ ]]; then
                reading_degraded=false
            fi
        done <"${mcp_file}"

        if [[ ${#degraded_mcps[@]} -gt 0 ]]; then
            machineconfig_issues+=("Degraded MachineConfigPools: ${degraded_mcps[*]}")
        fi
    fi

    # Check MachineConfigs
    local mc_file="cluster-scoped-resources/machineconfiguration.openshift.io/machineconfigs.yaml"
    if [[ -f ${mc_file} ]]; then
        local mc_count
        mc_count=$(grep -c "^[[:space:]]*name:" "${mc_file}" 2>/dev/null || echo 0)

        if [[ ${mc_count} -eq 0 ]]; then
            machineconfig_issues+=("No MachineConfigs found")
        fi
    fi

    # Check machine-config-daemon pods
    local mcd_ns_dir="namespaces/openshift-machine-config-operator"
    if [[ -d ${mcd_ns_dir} ]]; then
        local pods_file="${mcd_ns_dir}/core/pods.yaml"
        if [[ -f ${pods_file} ]]; then
            local failed_mcd_pods=()
            local current_pod=""
            local pod_phase=""

            while IFS= read -r line; do
                if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*(.+)$ ]]; then
                    current_pod="${BASH_REMATCH[1]}"
                elif [[ ${line} =~ ^[[:space:]]*phase:[[:space:]]*(.+)$ ]]; then
                    pod_phase="${BASH_REMATCH[1]}"

                    if [[ ${current_pod} =~ machine-config-daemon ]]; then
                        if [[ ${pod_phase} != "Running" ]]; then
                            failed_mcd_pods+=("${current_pod}: ${pod_phase}")
                        fi
                    fi
                fi
            done <"${pods_file}"

            if [[ ${#failed_mcd_pods[@]} -gt 0 ]]; then
                machineconfig_issues+=("Failed machine-config-daemon pods: ${failed_mcd_pods[*]}")
            fi
        fi
    fi

    # Check nodes annotation for machine config
    local nodes_file="cluster-scoped-resources/core/nodes.yaml"
    if [[ -f ${nodes_file} ]]; then
        local nodes_without_config=()
        local current_node=""
        local has_config_annotation=false

        while IFS= read -r line; do
            if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*(.+)$ ]]; then
                current_node="${BASH_REMATCH[1]}"
                has_config_annotation=false
            elif [[ ${line} =~ ^[[:space:]]*machineconfiguration.openshift.io/currentConfig: ]]; then
                has_config_annotation=true
            elif [[ ${line} =~ ^[[:space:]]*labels:$ ]]; then
                # End of node entry
                if [[ ${has_config_annotation} == false ]]; then
                    nodes_without_config+=("${current_node}")
                fi
            fi
        done <"${nodes_file}"

        if [[ ${#nodes_without_config[@]} -gt 0 ]]; then
            machineconfig_issues+=("Nodes without machine config annotation: ${nodes_without_config[*]}")
        fi
    fi

    # Report findings
    if [[ ${#machineconfig_issues[@]} -gt 0 ]]; then
        echo "Machine configuration issues found:" >&2
        printf '%s\n' "${machineconfig_issues[@]}" >&2
        exit ${RC_SKIPPED}
    fi

    return 0
}

# Function to analyze machine config from live cluster
analyze_machineconfig_live() {
    if ! command -v oc >/dev/null 2>&1; then
        echo "oc command not found" >&2
        exit ${RC_SKIPPED}
    fi

    # Check if we can connect to cluster
    if ! oc whoami >/dev/null 2>&1; then
        echo "Cannot connect to OpenShift cluster" >&2
        exit ${RC_SKIPPED}
    fi

    local machineconfig_issues=()

    # Check machine-config operator
    local mco_operator_status
    mco_operator_status=$(oc get clusteroperator machine-config --no-headers 2>/dev/null | awk '{print $2" "$3" "$4}')

    if [[ ${mco_operator_status} != "True False False" ]]; then
        machineconfig_issues+=("Machine-config operator not healthy: ${mco_operator_status}")
    fi

    # Check MachineConfigPools
    local degraded_mcps
    degraded_mcps=$(oc get machineconfigpool --no-headers 2>/dev/null | grep -v "True.*False.*False" | awk '{print $1": "$2" "$3" "$4}')

    if [[ -n ${degraded_mcps} ]]; then
        machineconfig_issues+=("Degraded MachineConfigPools: ${degraded_mcps}")
    fi

    # Check MachineConfigs
    local mc_count
    mc_count=$(oc get machineconfig --no-headers 2>/dev/null | wc -l)

    if [[ ${mc_count} -eq 0 ]]; then
        machineconfig_issues+=("No MachineConfigs found")
    fi

    # Check machine-config-daemon pods
    local failed_mcd_pods
    failed_mcd_pods=$(oc get pods -n openshift-machine-config-operator --no-headers 2>/dev/null | grep machine-config-daemon | grep -v "Running" | awk '{print $1": "$3}')

    if [[ -n ${failed_mcd_pods} ]]; then
        machineconfig_issues+=("Failed machine-config-daemon pods: ${failed_mcd_pods}")
    fi

    # Check nodes annotation for machine config
    local nodes_without_config
    nodes_without_config=$(oc get nodes -o json 2>/dev/null | jq -r '.items[] | select(.metadata.annotations["machineconfiguration.openshift.io/currentConfig"] == null) | .metadata.name' 2>/dev/null)

    if [[ -n ${nodes_without_config} ]]; then
        machineconfig_issues+=("Nodes without machine config annotation: ${nodes_without_config}")
    fi

    # Check for nodes waiting for machine config updates
    local updating_nodes
    updating_nodes=$(oc get nodes -o json 2>/dev/null | jq -r '.items[] | select(.metadata.annotations["machineconfiguration.openshift.io/state"] == "Working") | .metadata.name' 2>/dev/null)

    if [[ -n ${updating_nodes} ]]; then
        machineconfig_issues+=("Nodes updating machine config: ${updating_nodes}")
    fi

    # Check machine-config-operator logs for errors
    local mco_log_errors
    mco_log_errors=$(oc logs -n openshift-machine-config-operator deployment/machine-config-operator --tail=100 2>/dev/null | grep -i error | wc -l)

    if [[ ${mco_log_errors} -gt 10 ]]; then
        machineconfig_issues+=("Many errors in machine-config-operator logs: ${mco_log_errors} errors")
    fi

    # Check for MachineConfigPool paused state
    local paused_mcps
    paused_mcps=$(oc get machineconfigpool -o json 2>/dev/null | jq -r '.items[] | select(.spec.paused == true) | .metadata.name' 2>/dev/null)

    if [[ -n ${paused_mcps} ]]; then
        machineconfig_issues+=("Paused MachineConfigPools: ${paused_mcps}")
    fi

    # Check ContainerRuntimeConfig
    local crc_count
    crc_count=$(oc get containerruntimeconfig --no-headers 2>/dev/null | wc -l)

    if [[ ${crc_count} -eq 0 ]]; then
        machineconfig_issues+=("No ContainerRuntimeConfig found")
    fi

    # Check KubeletConfig
    local kc_count
    kc_count=$(oc get kubeletconfig --no-headers 2>/dev/null | wc -l)

    if [[ ${kc_count} -eq 0 ]]; then
        machineconfig_issues+=("No KubeletConfig found")
    fi

    # Check for machine config render failures
    local render_failures
    render_failures=$(oc get machineconfig --no-headers 2>/dev/null | grep -c "rendered-.*-failed")

    if [[ ${render_failures} -gt 0 ]]; then
        machineconfig_issues+=("Machine config render failures: ${render_failures}")
    fi

    # Report findings
    if [[ ${#machineconfig_issues[@]} -gt 0 ]]; then
        echo "Machine configuration issues found:" >&2
        printf '%s\n' "${machineconfig_issues[@]}" >&2
        exit ${RC_SKIPPED}
    fi

    return 0
}

# Main execution
if is_mustgather; then
    analyze_machineconfig_mustgather
    result=$?
else
    analyze_machineconfig_live
    result=$?
fi

if [[ ${result} -eq 0 ]]; then
    exit "${RC_OKAY}"
else
    exit "${RC_FAILED}"
fi
