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

# long_name: OpenShift Node Health Check
# description: OpenShift Node Health validation and monitoring
# priority: 880
# Validates OpenShift node health, resource usage, and readiness

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

is_required_file "${RISU_BASE}/common-functions.sh"

# Function to check if we're analyzing a Must Gather
is_mustgather() {
    [[ ${RISU_LIVE} != "1" ]] && [[ -d "namespaces" || -d "cluster-scoped-resources" ]]
}

# Function to get node information from Must Gather
get_nodes_from_mustgather() {
    local nodes_file=""

    # Try different possible locations for nodes data
    if [[ -f "cluster-scoped-resources/core/nodes.yaml" ]]; then
        nodes_file="cluster-scoped-resources/core/nodes.yaml"
    elif [[ -f "cluster-scoped-resources/nodes.yaml" ]]; then
        nodes_file="cluster-scoped-resources/nodes.yaml"
    elif [[ -f "nodes.yaml" ]]; then
        nodes_file="nodes.yaml"
    fi

    if [[ -n ${nodes_file} && -f ${nodes_file} ]]; then
        echo "${nodes_file}" >&2
    else
        exit ${RC_SKIPPED}
    fi
}

# Function to analyze node health from Must Gather
analyze_nodes_mustgather() {
    local nodes_file
    nodes_file=$(get_nodes_from_mustgather)

    if [[ -z ${nodes_file} ]]; then
        echo "No nodes data found in Must Gather" >&2
        exit ${RC_SKIPPED}
    fi

    local not_ready_nodes=()
    local nodes_with_issues=()

    # Parse YAML to find node status
    while IFS= read -r line; do
        if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*(.+)$ ]]; then
            current_node="${BASH_REMATCH[1]}"
        elif [[ ${line} =~ ^[[:space:]]*type:[[:space:]]*Ready$ ]]; then
            in_ready_condition=true
        elif [[ ${in_ready_condition} == true ]] && [[ ${line} =~ ^[[:space:]]*status:[[:space:]]*(.+)$ ]]; then
            status="${BASH_REMATCH[1]}"
            if [[ ${status} != "True" ]]; then
                not_ready_nodes+=("${current_node}")
            fi
            in_ready_condition=false
        fi
    done <"${nodes_file}"

    # Check for node conditions indicating issues
    while IFS= read -r line; do
        if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*(.+)$ ]]; then
            current_node="${BASH_REMATCH[1]}"
        elif [[ ${line} =~ ^[[:space:]]*type:[[:space:]]*(MemoryPressure|DiskPressure|PIDPressure|NetworkUnavailable)$ ]]; then
            condition_type="${BASH_REMATCH[1]}"
            checking_condition=true
        elif [[ ${checking_condition} == true ]] && [[ ${line} =~ ^[[:space:]]*status:[[:space:]]*True$ ]]; then
            nodes_with_issues+=("${current_node}: ${condition_type}")
            checking_condition=false
        elif [[ ${checking_condition} == true ]] && [[ ${line} =~ ^[[:space:]]*status:[[:space:]]*False$ ]]; then
            checking_condition=false
        fi
    done <"${nodes_file}"

    # Report findings
    if [[ ${#not_ready_nodes[@]} -gt 0 ]]; then
        echo "Not Ready nodes found:" >&2
        printf '%s\n' "${not_ready_nodes[@]}" >&2
        exit ${RC_SKIPPED}
    fi

    if [[ ${#nodes_with_issues[@]} -gt 0 ]]; then
        echo "Nodes with conditions indicating issues:" >&2
        printf '%s\n' "${nodes_with_issues[@]}" >&2
        exit ${RC_SKIPPED}
    fi

    return 0
}

# Function to analyze node health from live cluster
analyze_nodes_live() {
    if ! command -v oc >/dev/null 2>&1; then
        echo "oc command not found" >&2
        exit ${RC_SKIPPED}
    fi

    # Check if we can connect to cluster
    if ! oc whoami >/dev/null 2>&1; then
        echo "Cannot connect to OpenShift cluster" >&2
        exit ${RC_SKIPPED}
    fi

    local not_ready_nodes
    not_ready_nodes=$(oc get nodes --no-headers | grep -v " Ready " | awk '{print $1}')

    if [[ -n ${not_ready_nodes} ]]; then
        echo "Not Ready nodes found:" >&2
        echo "${not_ready_nodes}" >&2
        exit ${RC_SKIPPED}
    fi

    # Check for nodes with conditions
    local nodes_with_issues
    nodes_with_issues=$(oc get nodes -o json | jq -r '.items[] | select(.status.conditions[]? | select(.type == "MemoryPressure" or .type == "DiskPressure" or .type == "PIDPressure" or .type == "NetworkUnavailable") | .status == "True") | .metadata.name')

    if [[ -n ${nodes_with_issues} ]]; then
        echo "Nodes with pressure conditions:" >&2
        echo "${nodes_with_issues}" >&2
        exit ${RC_SKIPPED}
    fi

    return 0
}

# Main execution
if is_mustgather; then
    analyze_nodes_mustgather
    result=$?
else
    analyze_nodes_live
    result=$?
fi

if [[ ${result} -eq 0 ]]; then
    exit "${RC_OKAY}"
else
    exit "${RC_FAILED}"
fi
