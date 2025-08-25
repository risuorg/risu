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

# long_name: OpenShift Storage Health Check
# description: Validates OpenShift storage health and persistent volume status
# priority: 850

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

is_required_file "${RISU_BASE}/common-functions.sh"

# Function to check if we're analyzing a Must Gather
is_mustgather() {
    [[ ${RISU_LIVE} != "1" ]] && [[ -d "namespaces" || -d "cluster-scoped-resources" ]]
}

# Function to analyze storage from Must Gather
analyze_storage_mustgather() {
    local storage_issues=()

    # Check storage operator health
    local storage_co_file="cluster-scoped-resources/config.openshift.io/clusteroperators.yaml"
    if [[ -f ${storage_co_file} ]]; then
        local in_storage_operator=false
        local storage_available=""
        local storage_degraded=""

        while IFS= read -r line; do
            if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*storage$ ]]; then
                in_storage_operator=true
            elif [[ ${in_storage_operator} == true ]] && [[ ${line} =~ ^[[:space:]]*type:[[:space:]]*Available$ ]]; then
                reading_available=true
            elif [[ ${in_storage_operator} == true ]] && [[ ${line} =~ ^[[:space:]]*type:[[:space:]]*Degraded$ ]]; then
                reading_degraded=true
            elif [[ ${reading_available} == true ]] && [[ ${line} =~ ^[[:space:]]*status:[[:space:]]*(.+)$ ]]; then
                storage_available="${BASH_REMATCH[1]}"
                reading_available=false
            elif [[ ${reading_degraded} == true ]] && [[ ${line} =~ ^[[:space:]]*status:[[:space:]]*(.+)$ ]]; then
                storage_degraded="${BASH_REMATCH[1]}"
                reading_degraded=false
                break
            fi
        done <"${storage_co_file}"

        if [[ ${storage_available} != "True" ]]; then
            storage_issues+=("Storage operator not available: ${storage_available}")
        fi

        if [[ ${storage_degraded} == "True" ]]; then
            storage_issues+=("Storage operator degraded: ${storage_degraded}")
        fi
    fi

    # Check PersistentVolumes
    local pv_file="cluster-scoped-resources/core/persistentvolumes.yaml"
    if [[ -f ${pv_file} ]]; then
        local failed_pvs=()
        local current_pv=""
        local pv_phase=""

        while IFS= read -r line; do
            if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*(.+)$ ]]; then
                current_pv="${BASH_REMATCH[1]}"
            elif [[ ${line} =~ ^[[:space:]]*phase:[[:space:]]*(.+)$ ]]; then
                pv_phase="${BASH_REMATCH[1]}"

                if [[ ${pv_phase} == "Failed" ]]; then
                    failed_pvs+=("${current_pv}")
                fi
            fi
        done <"${pv_file}"

        if [[ ${#failed_pvs[@]} -gt 0 ]]; then
            storage_issues+=("Failed PersistentVolumes: ${failed_pvs[*]}")
        fi
    fi

    # Check PersistentVolumeClaims across all namespaces
    local pending_pvcs=()
    if [[ -d "namespaces" ]]; then
        for ns_dir in namespaces/*; do
            if [[ -d ${ns_dir} ]]; then
                local namespace=$(basename "${ns_dir}")
                local pvc_file="${ns_dir}/core/persistentvolumeclaims.yaml"

                if [[ -f ${pvc_file} ]]; then
                    local current_pvc=""
                    local pvc_phase=""

                    while IFS= read -r line; do
                        if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*(.+)$ ]]; then
                            current_pvc="${BASH_REMATCH[1]}"
                        elif [[ ${line} =~ ^[[:space:]]*phase:[[:space:]]*(.+)$ ]]; then
                            pvc_phase="${BASH_REMATCH[1]}"

                            if [[ ${pvc_phase} == "Pending" ]]; then
                                pending_pvcs+=("${namespace}/${current_pvc}")
                            fi
                        fi
                    done <"${pvc_file}"
                fi
            fi
        done
    fi

    if [[ ${#pending_pvcs[@]} -gt 0 ]]; then
        storage_issues+=("Pending PersistentVolumeClaims: ${pending_pvcs[*]}")
    fi

    # Check StorageClasses
    local sc_file="cluster-scoped-resources/storage.k8s.io/storageclasses.yaml"
    if [[ -f ${sc_file} ]]; then
        local sc_count
        sc_count=$(grep -c "^[[:space:]]*name:" "${sc_file}" 2>/dev/null || echo 0)

        if [[ ${sc_count} -eq 0 ]]; then
            storage_issues+=("No StorageClasses found")
        fi
    fi

    # Check CSI drivers
    local csi_driver_file="cluster-scoped-resources/storage.k8s.io/csidrivers.yaml"
    if [[ -f ${csi_driver_file} ]]; then
        local csi_driver_count
        csi_driver_count=$(grep -c "^[[:space:]]*name:" "${csi_driver_file}" 2>/dev/null || echo 0)

        if [[ ${csi_driver_count} -eq 0 ]]; then
            storage_issues+=("No CSI drivers found")
        fi
    fi

    # Report findings
    if [[ ${#storage_issues[@]} -gt 0 ]]; then
        echo "Storage issues found:" >&2
        printf '%s\n' "${storage_issues[@]}" >&2
        exit ${RC_SKIPPED}
    fi

    return 0
}

# Function to analyze storage from live cluster
analyze_storage_live() {
    if ! command -v oc >/dev/null 2>&1; then
        echo "oc command not found" >&2
        exit ${RC_SKIPPED}
    fi

    # Check if we can connect to cluster
    if ! oc whoami >/dev/null 2>&1; then
        echo "Cannot connect to OpenShift cluster" >&2
        exit ${RC_SKIPPED}
    fi

    local storage_issues=()

    # Check storage operator health
    local storage_operator_status
    storage_operator_status=$(oc get clusteroperator storage --no-headers 2>/dev/null | awk '{print $2" "$3" "$4}')

    if [[ ${storage_operator_status} != "True False False" ]]; then
        storage_issues+=("Storage operator not healthy: ${storage_operator_status}")
    fi

    # Check for failed PVs
    local failed_pvs
    failed_pvs=$(oc get pv --no-headers 2>/dev/null | grep Failed | awk '{print $1}')

    if [[ -n ${failed_pvs} ]]; then
        storage_issues+=("Failed PersistentVolumes: ${failed_pvs}")
    fi

    # Check for pending PVCs
    local pending_pvcs
    pending_pvcs=$(oc get pvc --all-namespaces --no-headers 2>/dev/null | grep Pending | awk '{print $1"/"$2}')

    if [[ -n ${pending_pvcs} ]]; then
        storage_issues+=("Pending PersistentVolumeClaims: ${pending_pvcs}")
    fi

    # Check StorageClasses
    local sc_count
    sc_count=$(oc get storageclass --no-headers 2>/dev/null | wc -l)

    if [[ ${sc_count} -eq 0 ]]; then
        storage_issues+=("No StorageClasses found")
    fi

    # Check for default StorageClass
    local default_sc
    default_sc=$(oc get storageclass --no-headers 2>/dev/null | grep "(default)" | wc -l)

    if [[ ${default_sc} -eq 0 ]]; then
        storage_issues+=("No default StorageClass found")
    elif [[ ${default_sc} -gt 1 ]]; then
        storage_issues+=("Multiple default StorageClasses found: ${default_sc}")
    fi

    # Check CSI drivers
    local csi_driver_count
    csi_driver_count=$(oc get csidriver --no-headers 2>/dev/null | wc -l)

    if [[ ${csi_driver_count} -eq 0 ]]; then
        storage_issues+=("No CSI drivers found")
    fi

    # Check CSI node pods
    local csi_pods_status
    csi_pods_status=$(oc get pods --all-namespaces --no-headers 2>/dev/null | grep -E "csi-|driver" | grep -v Running)

    if [[ -n ${csi_pods_status} ]]; then
        local csi_pod_count
        csi_pod_count=$(echo "${csi_pods_status}" | wc -l)
        storage_issues+=("${csi_pod_count} CSI pods not running")
    fi

    # Check for VolumeSnapshot CRDs
    local snapshot_crd_count
    snapshot_crd_count=$(oc get crd --no-headers 2>/dev/null | grep -c "snapshot.storage.k8s.io")

    if [[ ${snapshot_crd_count} -eq 0 ]]; then
        storage_issues+=("Volume snapshot CRDs not found")
    fi

    # Report findings
    if [[ ${#storage_issues[@]} -gt 0 ]]; then
        echo "Storage issues found:" >&2
        printf '%s\n' "${storage_issues[@]}" >&2
        exit ${RC_SKIPPED}
    fi

    return 0
}

# Main execution
if is_mustgather; then
    analyze_storage_mustgather
    result=$?
else
    analyze_storage_live
    result=$?
fi

if [[ ${result} -eq 0 ]]; then
    exit "${RC_OKAY}"
else
    exit "${RC_FAILED}"
fi
