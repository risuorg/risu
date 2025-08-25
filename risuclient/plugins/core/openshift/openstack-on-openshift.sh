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

# long_name: OpenStack on OpenShift Health Check
# description: Validates OpenStack integration on OpenShift
# priority: 750

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

is_required_file "${RISU_BASE}/common-functions.sh"

# Function to check if we're analyzing a Must Gather
is_mustgather() {
    [[ ${RISU_LIVE} != "1" ]] && [[ -d "namespaces" || -d "cluster-scoped-resources" ]]
}

# Function to analyze OpenStack from Must Gather
analyze_openstack_mustgather() {
    local openstack_issues=()

    # Check for OpenStack namespaces
    local openstack_namespaces=()
    if [[ -d "namespaces" ]]; then
        for ns_dir in namespaces/*; do
            if [[ -d ${ns_dir} ]]; then
                local namespace=$(basename "${ns_dir}")
                # Look for OpenStack-related namespaces
                if [[ ${namespace} =~ ^(openstack|rhosp) ]]; then
                    openstack_namespaces+=("${namespace}")
                fi
            fi
        done
    fi

    if [[ ${#openstack_namespaces[@]} -eq 0 ]]; then
        echo "No OpenStack namespaces found - OpenStack may not be deployed" >&2
        exit "${RC_SKIPPED}"
    fi

    # Check OpenStack operators
    local openstack_operators_issues=()
    for ns in "${openstack_namespaces[@]}"; do
        local ns_dir="namespaces/${ns}"

        # Check for OpenStack control plane operators
        local operators_file="${ns_dir}/operators.coreos.com/subscriptions.yaml"
        if [[ -f ${operators_file} ]]; then
            local openstack_subs=()
            local current_sub=""
            local sub_state=""

            while IFS= read -r line; do
                if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*(.+)$ ]]; then
                    current_sub="${BASH_REMATCH[1]}"
                elif [[ ${line} =~ ^[[:space:]]*state:[[:space:]]*(.+)$ ]]; then
                    sub_state="${BASH_REMATCH[1]}"

                    if [[ ${current_sub} =~ (openstack|rhosp) ]]; then
                        openstack_subs+=("${current_sub}")

                        if [[ ${sub_state} != "AtLatestKnown" ]]; then
                            openstack_operators_issues+=("${ns}/${current_sub}: ${sub_state}")
                        fi
                    fi
                fi
            done <"${operators_file}"
        fi

        # Check OpenStack service pods
        local pods_file="${ns_dir}/core/pods.yaml"
        if [[ -f ${pods_file} ]]; then
            local openstack_pods=()
            local failed_pods=()
            local current_pod=""
            local pod_phase=""

            while IFS= read -r line; do
                if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*(.+)$ ]]; then
                    current_pod="${BASH_REMATCH[1]}"
                elif [[ ${line} =~ ^[[:space:]]*phase:[[:space:]]*(.+)$ ]]; then
                    pod_phase="${BASH_REMATCH[1]}"

                    # Check for OpenStack service pods
                    if [[ ${current_pod} =~ (keystone|nova|neutron|cinder|glance|heat|swift|octavia|manila|barbican|designate) ]]; then
                        openstack_pods+=("${current_pod}")

                        if [[ ${pod_phase} != "Running" ]]; then
                            failed_pods+=("${ns}/${current_pod}: ${pod_phase}")
                        fi
                    fi
                fi
            done <"${pods_file}"

            if [[ ${#failed_pods[@]} -gt 0 ]]; then
                openstack_issues+=("${failed_pods[@]}")
            fi
        fi
    done

    if [[ ${#openstack_operators_issues[@]} -gt 0 ]]; then
        openstack_issues+=("OpenStack operator issues: ${openstack_operators_issues[*]}")
    fi

    # Check OpenStack control plane CRDs
    local openstack_crds_file="cluster-scoped-resources/apiextensions.k8s.io/customresourcedefinitions.yaml"
    if [[ -f ${openstack_crds_file} ]]; then
        local openstack_crd_count
        openstack_crd_count=$(grep -c "group.*openstack" "${openstack_crds_file}" 2>/dev/null || echo 0)

        if [[ ${openstack_crd_count} -eq 0 ]]; then
            openstack_issues+=("No OpenStack CRDs found")
        fi
    fi

    # Check OpenStack databases
    local db_issues=()
    for ns in "${openstack_namespaces[@]}"; do
        local ns_dir="namespaces/${ns}"
        local pods_file="${ns_dir}/core/pods.yaml"

        if [[ -f ${pods_file} ]]; then
            local db_pods=()
            local current_pod=""
            local pod_phase=""

            while IFS= read -r line; do
                if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*(.+)$ ]]; then
                    current_pod="${BASH_REMATCH[1]}"
                elif [[ ${line} =~ ^[[:space:]]*phase:[[:space:]]*(.+)$ ]]; then
                    pod_phase="${BASH_REMATCH[1]}"

                    # Check for database pods
                    if [[ ${current_pod} =~ (mysql|mariadb|galera|rabbitmq|redis|memcached) ]]; then
                        db_pods+=("${current_pod}")

                        if [[ ${pod_phase} != "Running" ]]; then
                            db_issues+=("${ns}/${current_pod}: ${pod_phase}")
                        fi
                    fi
                fi
            done <"${pods_file}"
        fi
    done

    if [[ ${#db_issues[@]} -gt 0 ]]; then
        openstack_issues+=("OpenStack database issues: ${db_issues[*]}")
    fi

    # Report findings
    if [[ ${#openstack_issues[@]} -gt 0 ]]; then
        echo "OpenStack on OpenShift issues found:" >&2
        printf '%s\n' "${openstack_issues[@]}" >&2
        exit ${RC_SKIPPED}
    fi

    return 0
}

# Function to analyze OpenStack from live cluster
analyze_openstack_live() {
    if ! command -v oc >/dev/null 2>&1; then
        echo "oc command not found" >&2
        exit ${RC_SKIPPED}
    fi

    # Check if we can connect to cluster
    if ! oc whoami >/dev/null 2>&1; then
        echo "Cannot connect to OpenShift cluster" >&2
        exit ${RC_SKIPPED}
    fi

    local openstack_issues=()

    # Check for OpenStack namespaces
    local openstack_namespaces
    openstack_namespaces=$(oc get namespaces --no-headers 2>/dev/null | grep -E "^(openstack|rhosp)" | awk '{print $1}')

    if [[ -z ${openstack_namespaces} ]]; then
        echo "No OpenStack namespaces found - OpenStack may not be deployed" >&2
        exit "${RC_SKIPPED}"
    fi

    # Check OpenStack operators
    local openstack_operators_issues
    openstack_operators_issues=$(oc get subscriptions --all-namespaces --no-headers 2>/dev/null | grep -E "(openstack|rhosp)" | grep -v "AtLatestKnown" | awk '{print $1"/"$2": "$4}')

    if [[ -n ${openstack_operators_issues} ]]; then
        openstack_issues+=("OpenStack operator issues: ${openstack_operators_issues}")
    fi

    # Check OpenStack service pods
    local failed_openstack_pods
    failed_openstack_pods=$(oc get pods --all-namespaces --no-headers 2>/dev/null | grep -E "(keystone|nova|neutron|cinder|glance|heat|swift|octavia|manila|barbican|designate)" | grep -v "Running" | awk '{print $1"/"$2": "$3}')

    if [[ -n ${failed_openstack_pods} ]]; then
        openstack_issues+=("Failed OpenStack service pods: ${failed_openstack_pods}")
    fi

    # Check OpenStack control plane CRDs
    local openstack_crd_count
    openstack_crd_count=$(oc get crd --no-headers 2>/dev/null | grep -c "openstack")

    if [[ ${openstack_crd_count} -eq 0 ]]; then
        openstack_issues+=("No OpenStack CRDs found")
    fi

    # Check OpenStack databases
    local db_issues
    db_issues=$(oc get pods --all-namespaces --no-headers 2>/dev/null | grep -E "(mysql|mariadb|galera|rabbitmq|redis|memcached)" | grep -E "^(openstack|rhosp)" | grep -v "Running" | awk '{print $1"/"$2": "$3}')

    if [[ -n ${db_issues} ]]; then
        openstack_issues+=("OpenStack database issues: ${db_issues}")
    fi

    # Check OpenStack control plane custom resources
    local openstack_cr_issues=()
    local openstack_crs=("openstackcontrolplane" "openstackversion" "openstacknetconfig")

    for cr in "${openstack_crs[@]}"; do
        if oc get crd "${cr}.openstack.org" >/dev/null 2>&1; then
            local cr_status
            cr_status=$(oc get "${cr}" --all-namespaces --no-headers 2>/dev/null | grep -v "Ready" | awk '{print $1"/"$2": "$3}')

            if [[ -n ${cr_status} ]]; then
                openstack_cr_issues+=("${cr}: ${cr_status}")
            fi
        fi
    done

    if [[ ${#openstack_cr_issues[@]} -gt 0 ]]; then
        openstack_issues+=("OpenStack control plane issues: ${openstack_cr_issues[*]}")
    fi

    # Check OpenStack networking
    local network_issues
    network_issues=$(oc get pods --all-namespaces --no-headers 2>/dev/null | grep -E "(neutron|ovn)" | grep -E "^(openstack|rhosp)" | grep -v "Running" | awk '{print $1"/"$2": "$3}')

    if [[ -n ${network_issues} ]]; then
        openstack_issues+=("OpenStack networking issues: ${network_issues}")
    fi

    # Check OpenStack storage
    local storage_issues
    storage_issues=$(oc get pods --all-namespaces --no-headers 2>/dev/null | grep -E "(cinder|swift|ceph)" | grep -E "^(openstack|rhosp)" | grep -v "Running" | awk '{print $1"/"$2": "$3}')

    if [[ -n ${storage_issues} ]]; then
        openstack_issues+=("OpenStack storage issues: ${storage_issues}")
    fi

    # Report findings
    if [[ ${#openstack_issues[@]} -gt 0 ]]; then
        echo "OpenStack on OpenShift issues found:" >&2
        printf '%s\n' "${openstack_issues[@]}" >&2
        exit ${RC_SKIPPED}
    fi

    return 0
}

# Main execution
if is_mustgather; then
    analyze_openstack_mustgather
    result=$?
else
    analyze_openstack_live
    result=$?
fi

if [[ ${result} -eq 0 ]]; then
    exit "${RC_OKAY}"
else
    exit "${RC_FAILED}"
fi
