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

# long_name: OpenShift Cluster Version and Upgrade Status Check
# description: Validates OpenShift cluster version and upgrade status
# priority: 960

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

is_required_file "${RISU_BASE}/common-functions.sh"

# Function to check if we're analyzing a Must Gather
is_mustgather() {
    [[ ${RISU_LIVE} != "1" ]] && [[ -d "namespaces" || -d "cluster-scoped-resources" ]]
}

# Function to analyze cluster version from Must Gather
analyze_version_mustgather() {
    local cv_file="cluster-scoped-resources/config.openshift.io/clusterversions.yaml"

    if [[ ! -f ${cv_file} ]]; then
        echo "ClusterVersion data not found in Must Gather" >&2
        exit ${RC_SKIPPED}
    fi

    local current_version=""
    local desired_version=""
    local upgrade_progressing=false
    local upgrade_available=false
    local upgrade_degraded=false
    local issues_found=false

    while IFS= read -r line; do
        if [[ ${line} =~ ^[[:space:]]*version:[[:space:]]*(.+)$ ]]; then
            current_version="${BASH_REMATCH[1]}"
        elif [[ ${line} =~ ^[[:space:]]*image:[[:space:]]*(.+)$ ]]; then
            # Extract version from image tag
            if [[ ${BASH_REMATCH[1]} =~ :v?([0-9]+\.[0-9]+\.[0-9]+) ]]; then
                desired_version="${BASH_REMATCH[1]}"
            fi
        elif [[ ${line} =~ ^[[:space:]]*type:[[:space:]]*Progressing$ ]]; then
            reading_progressing=true
        elif [[ ${line} =~ ^[[:space:]]*type:[[:space:]]*Available$ ]]; then
            reading_available=true
        elif [[ ${line} =~ ^[[:space:]]*type:[[:space:]]*Failing$ ]]; then
            reading_failing=true
        elif [[ ${reading_progressing} == true ]] && [[ ${line} =~ ^[[:space:]]*status:[[:space:]]*True$ ]]; then
            upgrade_progressing=true
            reading_progressing=false
        elif [[ ${reading_available} == true ]] && [[ ${line} =~ ^[[:space:]]*status:[[:space:]]*False$ ]]; then
            upgrade_available=false
            reading_available=false
        elif [[ ${reading_failing} == true ]] && [[ ${line} =~ ^[[:space:]]*status:[[:space:]]*True$ ]]; then
            upgrade_degraded=true
            reading_failing=false
        fi
    done <"${cv_file}"

    # Check for upgrade issues
    if [[ ${upgrade_degraded} == true ]]; then
        echo "Cluster upgrade is failing" >&2
        issues_found=true
    fi

    if [[ ${upgrade_progressing} == true ]]; then
        echo "Cluster upgrade is in progress from ${current_version} to ${desired_version}" >&2
        # This is informational, not necessarily an issue
    fi

    if [[ ${upgrade_available} == false ]] && [[ ${upgrade_progressing} == false ]]; then
        echo "Cluster upgrade is not available" >&2
        issues_found=true
    fi

    # Check for version mismatch
    if [[ -n ${current_version} && -n ${desired_version} && ${current_version} != "${desired_version}" ]]; then
        echo "Version mismatch: current=${current_version}, desired=${desired_version}" >&2
        issues_found=true
    fi

    if [[ ${issues_found} == true ]]; then
        exit ${RC_SKIPPED}
    fi

    return 0
}

# Function to analyze cluster version from live cluster
analyze_version_live() {
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

    # Get cluster version status
    local cv_status
    cv_status=$(oc get clusterversion version -o json 2>/dev/null)

    if [[ -z ${cv_status} ]]; then
        echo "Could not retrieve cluster version information" >&2
        exit ${RC_SKIPPED}
    fi

    # Check for upgrade failures
    local failing_condition
    failing_condition=$(echo "${cv_status}" | jq -r '.status.conditions[] | select(.type == "Failing" and .status == "True") | .message' 2>/dev/null)

    if [[ -n ${failing_condition} ]]; then
        echo "Cluster upgrade is failing: ${failing_condition}" >&2
        issues_found=true
    fi

    # Check for progressing upgrades
    local progressing_condition
    progressing_condition=$(echo "${cv_status}" | jq -r '.status.conditions[] | select(.type == "Progressing" and .status == "True") | .message' 2>/dev/null)

    if [[ -n ${progressing_condition} ]]; then
        echo "Cluster upgrade in progress: ${progressing_condition}" >&2
        # This is informational
    fi

    # Check for available updates
    local available_updates
    available_updates=$(oc adm upgrade 2>/dev/null | grep -c "^[0-9]")

    if [[ ${available_updates} -eq 0 ]]; then
        echo "No available updates found" >&2
        # This might be normal, so not marking as issue
    fi

    # Check cluster version operator health
    local cvo_status
    cvo_status=$(oc get clusteroperator version --no-headers | awk '{print $2" "$3" "$4}')

    if [[ ${cvo_status} != "True False False" ]]; then
        echo "Cluster Version Operator is not healthy: ${cvo_status}" >&2
        issues_found=true
    fi

    if [[ ${issues_found} == true ]]; then
        exit ${RC_SKIPPED}
    fi

    return 0
}

# Main execution
if is_mustgather; then
    analyze_version_mustgather
    result=$?
else
    analyze_version_live
    result=$?
fi

if [[ ${result} -eq 0 ]]; then
    exit "${RC_OKAY}"
else
    exit "${RC_FAILED}"
fi
