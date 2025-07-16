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

# long_name: OpenShift Events Analysis Check
# description: Analyzes OpenShift cluster events and error patterns
# priority: 740

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

is_required_file "${RISU_BASE}/common-functions.sh"

# Function to check if we're analyzing a Must Gather
is_mustgather() {
    [[ ${RISU_LIVE} != "1" ]] && [[ -d "namespaces" || -d "cluster-scoped-resources" ]]
}

# Function to analyze events from Must Gather
analyze_events_mustgather() {
    local events_issues=()

    # Analyze events across all namespaces
    local warning_events=()
    local error_events=()
    local failed_events=()

    if [[ -d "namespaces" ]]; then
        for ns_dir in namespaces/*; do
            if [[ -d ${ns_dir} ]]; then
                local namespace=$(basename "${ns_dir}")
                local events_file="${ns_dir}/core/events.yaml"

                if [[ -f ${events_file} ]]; then
                    # Count different types of events
                    local warning_count
                    warning_count=$(grep -c "type:[[:space:]]*Warning" "${events_file}" 2>/dev/null || echo 0)

                    if [[ ${warning_count} -gt 20 ]]; then
                        warning_events+=("${namespace}: ${warning_count} warnings")
                    fi

                    # Look for specific error patterns
                    local failed_pulls
                    failed_pulls=$(grep -c "reason:[[:space:]]*Failed" "${events_file}" 2>/dev/null || echo 0)

                    if [[ ${failed_pulls} -gt 0 ]]; then
                        failed_events+=("${namespace}: ${failed_pulls} failed events")
                    fi

                    # Check for image pull errors
                    local image_pull_errors
                    image_pull_errors=$(grep -c "reason:[[:space:]]*Failed.*image" "${events_file}" 2>/dev/null || echo 0)

                    if [[ ${image_pull_errors} -gt 0 ]]; then
                        error_events+=("${namespace}: ${image_pull_errors} image pull errors")
                    fi

                    # Check for scheduling errors
                    local scheduling_errors
                    scheduling_errors=$(grep -c "reason:[[:space:]]*FailedScheduling" "${events_file}" 2>/dev/null || echo 0)

                    if [[ ${scheduling_errors} -gt 0 ]]; then
                        error_events+=("${namespace}: ${scheduling_errors} scheduling errors")
                    fi

                    # Check for mounting errors
                    local mount_errors
                    mount_errors=$(grep -c "reason:[[:space:]]*FailedMount" "${events_file}" 2>/dev/null || echo 0)

                    if [[ ${mount_errors} -gt 0 ]]; then
                        error_events+=("${namespace}: ${mount_errors} mount errors")
                    fi

                    # Check for network errors
                    local network_errors
                    network_errors=$(grep -c "reason:[[:space:]]*NetworkNotReady" "${events_file}" 2>/dev/null || echo 0)

                    if [[ ${network_errors} -gt 0 ]]; then
                        error_events+=("${namespace}: ${network_errors} network errors")
                    fi

                    # Check for resource quota errors
                    local quota_errors
                    quota_errors=$(grep -c "reason:[[:space:]]*ExceededQuota" "${events_file}" 2>/dev/null || echo 0)

                    if [[ ${quota_errors} -gt 0 ]]; then
                        error_events+=("${namespace}: ${quota_errors} quota exceeded")
                    fi
                fi
            fi
        done
    fi

    if [[ ${#warning_events[@]} -gt 0 ]]; then
        events_issues+=("High warning events: ${warning_events[*]}")
    fi

    if [[ ${#error_events[@]} -gt 0 ]]; then
        events_issues+=("Error events: ${error_events[*]}")
    fi

    if [[ ${#failed_events[@]} -gt 0 ]]; then
        events_issues+=("Failed events: ${failed_events[*]}")
    fi

    # Check cluster-wide events
    local cluster_events_file="cluster-scoped-resources/core/events.yaml"
    if [[ -f ${cluster_events_file} ]]; then
        local cluster_warnings
        cluster_warnings=$(grep -c "type:[[:space:]]*Warning" "${cluster_events_file}" 2>/dev/null || echo 0)

        if [[ ${cluster_warnings} -gt 50 ]]; then
            events_issues+=("High cluster-wide warnings: ${cluster_warnings}")
        fi

        # Check for node events
        local node_events
        node_events=$(grep -c "reason:[[:space:]]*NodeNotReady" "${cluster_events_file}" 2>/dev/null || echo 0)

        if [[ ${node_events} -gt 0 ]]; then
            events_issues+=("Node not ready events: ${node_events}")
        fi

        # Check for system component events
        local system_events
        system_events=$(grep -c "reason:[[:space:]]*SystemOOM" "${cluster_events_file}" 2>/dev/null || echo 0)

        if [[ ${system_events} -gt 0 ]]; then
            events_issues+=("System OOM events: ${system_events}")
        fi
    fi

    # Report findings
    if [[ ${#events_issues[@]} -gt 0 ]]; then
        echo "Events analysis issues found:" >&2
        printf '%s\n' "${events_issues[@]}" >&2
        exit ${RC_SKIPPED}
    fi

    return 0
}

# Function to analyze events from live cluster
analyze_events_live() {
    if ! command -v oc >/dev/null 2>&1; then
        echo "oc command not found" >&2
        exit ${RC_SKIPPED}
    fi

    # Check if we can connect to cluster
    if ! oc whoami >/dev/null 2>&1; then
        echo "Cannot connect to OpenShift cluster" >&2
        exit ${RC_SKIPPED}
    fi

    local events_issues=()

    # Analyze warning events
    local warning_events
    warning_events=$(oc get events --all-namespaces --no-headers 2>/dev/null | grep Warning | wc -l)

    if [[ ${warning_events} -gt 100 ]]; then
        events_issues+=("High warning events: ${warning_events}")
    fi

    # Check for image pull errors
    local image_pull_errors
    image_pull_errors=$(oc get events --all-namespaces --no-headers 2>/dev/null | grep -c "Failed.*image")

    if [[ ${image_pull_errors} -gt 0 ]]; then
        events_issues+=("Image pull errors: ${image_pull_errors}")
    fi

    # Check for scheduling errors
    local scheduling_errors
    scheduling_errors=$(oc get events --all-namespaces --no-headers 2>/dev/null | grep -c "FailedScheduling")

    if [[ ${scheduling_errors} -gt 0 ]]; then
        events_issues+=("Scheduling errors: ${scheduling_errors}")
    fi

    # Check for mounting errors
    local mount_errors
    mount_errors=$(oc get events --all-namespaces --no-headers 2>/dev/null | grep -c "FailedMount")

    if [[ ${mount_errors} -gt 0 ]]; then
        events_issues+=("Mount errors: ${mount_errors}")
    fi

    # Check for network errors
    local network_errors
    network_errors=$(oc get events --all-namespaces --no-headers 2>/dev/null | grep -c "NetworkNotReady")

    if [[ ${network_errors} -gt 0 ]]; then
        events_issues+=("Network errors: ${network_errors}")
    fi

    # Check for resource quota errors
    local quota_errors
    quota_errors=$(oc get events --all-namespaces --no-headers 2>/dev/null | grep -c "ExceededQuota")

    if [[ ${quota_errors} -gt 0 ]]; then
        events_issues+=("Quota exceeded errors: ${quota_errors}")
    fi

    # Check for node events
    local node_events
    node_events=$(oc get events --all-namespaces --no-headers 2>/dev/null | grep -c "NodeNotReady")

    if [[ ${node_events} -gt 0 ]]; then
        events_issues+=("Node not ready events: ${node_events}")
    fi

    # Check for system component events
    local system_events
    system_events=$(oc get events --all-namespaces --no-headers 2>/dev/null | grep -c "SystemOOM")

    if [[ ${system_events} -gt 0 ]]; then
        events_issues+=("System OOM events: ${system_events}")
    fi

    # Check for frequent restart events
    local restart_events
    restart_events=$(oc get events --all-namespaces --no-headers 2>/dev/null | grep -c "Started.*container")

    if [[ ${restart_events} -gt 200 ]]; then
        events_issues+=("High container restart events: ${restart_events}")
    fi

    # Check for probe failure events
    local probe_failures
    probe_failures=$(oc get events --all-namespaces --no-headers 2>/dev/null | grep -c "Unhealthy")

    if [[ ${probe_failures} -gt 0 ]]; then
        events_issues+=("Probe failure events: ${probe_failures}")
    fi

    # Check for DNS errors
    local dns_errors
    dns_errors=$(oc get events --all-namespaces --no-headers 2>/dev/null | grep -c "DNSConfigForming")

    if [[ ${dns_errors} -gt 0 ]]; then
        events_issues+=("DNS configuration errors: ${dns_errors}")
    fi

    # Check for certificate errors
    local cert_errors
    cert_errors=$(oc get events --all-namespaces --no-headers 2>/dev/null | grep -c "CertificateError")

    if [[ ${cert_errors} -gt 0 ]]; then
        events_issues+=("Certificate errors: ${cert_errors}")
    fi

    # Check for authentication errors
    local auth_errors
    auth_errors=$(oc get events --all-namespaces --no-headers 2>/dev/null | grep -c "Forbidden")

    if [[ ${auth_errors} -gt 0 ]]; then
        events_issues+=("Authentication/authorization errors: ${auth_errors}")
    fi

    # Check for storage errors
    local storage_errors
    storage_errors=$(oc get events --all-namespaces --no-headers 2>/dev/null | grep -c "VolumeBinding")

    if [[ ${storage_errors} -gt 0 ]]; then
        events_issues+=("Storage binding errors: ${storage_errors}")
    fi

    # Check for recent events frequency
    local recent_events
    recent_events=$(oc get events --all-namespaces --sort-by='.lastTimestamp' --no-headers 2>/dev/null | tail -50 | wc -l)

    if [[ ${recent_events} -gt 45 ]]; then
        events_issues+=("High recent event frequency: ${recent_events} events")
    fi

    # Check for events from system namespaces
    local system_namespace_events
    system_namespace_events=$(oc get events --all-namespaces --no-headers 2>/dev/null | grep -E "^(openshift-|kube-)" | grep Warning | wc -l)

    if [[ ${system_namespace_events} -gt 20 ]]; then
        events_issues+=("System namespace warning events: ${system_namespace_events}")
    fi

    # Check for operator events
    local operator_events
    operator_events=$(oc get events --all-namespaces --no-headers 2>/dev/null | grep -i operator | grep Warning | wc -l)

    if [[ ${operator_events} -gt 10 ]]; then
        events_issues+=("Operator warning events: ${operator_events}")
    fi

    # Check for recurring events
    local recurring_events
    recurring_events=$(oc get events --all-namespaces --no-headers 2>/dev/null | awk '$5 > 10 {print $1"/"$3": "$5" occurrences"}' | wc -l)

    if [[ ${recurring_events} -gt 5 ]]; then
        events_issues+=("Recurring events: ${recurring_events} event types")
    fi

    # Report findings
    if [[ ${#events_issues[@]} -gt 0 ]]; then
        echo "Events analysis issues found:" >&2
        printf '%s\n' "${events_issues[@]}" >&2
        exit ${RC_SKIPPED}
    fi

    return 0
}

# Main execution
if is_mustgather; then
    analyze_events_mustgather
    result=$?
else
    analyze_events_live
    result=$?
fi

if [[ ${result} -eq 0 ]]; then
    exit "${RC_OKAY}"
else
    exit "${RC_FAILED}"
fi
