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

# long_name: OpenShift Backup and Restore Validation Check
# description: Validates OpenShift backup and restore configurations
# priority: 740

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

is_required_file "${RISU_BASE}/common-functions.sh"

# Function to check if we're analyzing a Must Gather
is_mustgather() {
    [[ ${RISU_LIVE} != "1" ]] && [[ -d "namespaces" || -d "cluster-scoped-resources" ]]
}

# Function to analyze backup/restore from Must Gather
analyze_backup_mustgather() {
    local backup_issues=()

    # Check for etcd backup CronJob
    local etcd_ns_dir="namespaces/openshift-etcd"
    if [[ -d ${etcd_ns_dir} ]]; then
        local cronjobs_file="${etcd_ns_dir}/batch/cronjobs.yaml"
        if [[ -f ${cronjobs_file} ]]; then
            local etcd_backup_count
            etcd_backup_count=$(grep -c "etcd-backup" "${cronjobs_file}" 2>/dev/null || echo 0)

            if [[ ${etcd_backup_count} -eq 0 ]]; then
                backup_issues+=("No etcd backup CronJob found")
            fi
        else
            backup_issues+=("No CronJobs found in etcd namespace")
        fi
    fi

    # Check for OADP/Velero operator
    local oadp_namespaces=("openshift-adp" "velero")
    local oadp_found=false

    for ns in "${oadp_namespaces[@]}"; do
        local ns_dir="namespaces/${ns}"
        if [[ -d ${ns_dir} ]]; then
            oadp_found=true

            # Check OADP pods
            local pods_file="${ns_dir}/core/pods.yaml"
            if [[ -f ${pods_file} ]]; then
                local failed_oadp_pods=()
                local current_pod=""
                local pod_phase=""

                while IFS= read -r line; do
                    if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*(.+)$ ]]; then
                        current_pod="${BASH_REMATCH[1]}"
                    elif [[ ${line} =~ ^[[:space:]]*phase:[[:space:]]*(.+)$ ]]; then
                        pod_phase="${BASH_REMATCH[1]}"

                        if [[ ${current_pod} =~ (velero|oadp|restic) ]]; then
                            if [[ ${pod_phase} != "Running" ]]; then
                                failed_oadp_pods+=("${ns}/${current_pod}: ${pod_phase}")
                            fi
                        fi
                    fi
                done <"${pods_file}"

                if [[ ${#failed_oadp_pods[@]} -gt 0 ]]; then
                    backup_issues+=("Failed OADP/Velero pods: ${failed_oadp_pods[*]}")
                fi
            fi
        fi
    done

    if [[ ${oadp_found} == false ]]; then
        backup_issues+=("No OADP/Velero operator found")
    fi

    # Check for backup storage locations
    local bsl_issues=()
    for ns in "${oadp_namespaces[@]}"; do
        local ns_dir="namespaces/${ns}"
        if [[ -d ${ns_dir} ]]; then
            local bsl_file="${ns_dir}/velero.io/backupstoragelocations.yaml"
            if [[ -f ${bsl_file} ]]; then
                local bsl_count
                bsl_count=$(grep -c "^[[:space:]]*name:" "${bsl_file}" 2>/dev/null || echo 0)

                if [[ ${bsl_count} -eq 0 ]]; then
                    bsl_issues+=("No backup storage locations in ${ns}")
                fi
            fi
        fi
    done

    if [[ ${#bsl_issues[@]} -gt 0 ]]; then
        backup_issues+=("${bsl_issues[@]}")
    fi

    # Check for recent backups
    local backup_schedules=()
    for ns in "${oadp_namespaces[@]}"; do
        local ns_dir="namespaces/${ns}"
        if [[ -d ${ns_dir} ]]; then
            local schedule_file="${ns_dir}/velero.io/schedules.yaml"
            if [[ -f ${schedule_file} ]]; then
                local schedule_count
                schedule_count=$(grep -c "^[[:space:]]*name:" "${schedule_file}" 2>/dev/null || echo 0)

                backup_schedules+=("${ns}: ${schedule_count} backup schedules")
            fi
        fi
    done

    if [[ ${#backup_schedules[@]} -eq 0 ]]; then
        backup_issues+=("No backup schedules found")
    fi

    # Check for Volume Snapshot Classes
    local vsc_file="cluster-scoped-resources/snapshot.storage.k8s.io/volumesnapshotclasses.yaml"
    if [[ -f ${vsc_file} ]]; then
        local vsc_count
        vsc_count=$(grep -c "^[[:space:]]*name:" "${vsc_file}" 2>/dev/null || echo 0)

        if [[ ${vsc_count} -eq 0 ]]; then
            backup_issues+=("No Volume Snapshot Classes found")
        fi
    fi

    # Check for persistent volume snapshots
    local pvs_file="cluster-scoped-resources/snapshot.storage.k8s.io/volumesnapshots.yaml"
    if [[ -f ${pvs_file} ]]; then
        local pvs_count
        pvs_count=$(grep -c "^[[:space:]]*name:" "${pvs_file}" 2>/dev/null || echo 0)

        if [[ ${pvs_count} -eq 0 ]]; then
            backup_issues+=("No volume snapshots found")
        fi
    fi

    # Report findings
    if [[ ${#backup_issues[@]} -gt 0 ]]; then
        echo "Backup and restore issues found:" >&2
        printf '%s\n' "${backup_issues[@]}" >&2
        exit ${RC_SKIPPED}
    fi

    return 0
}

# Function to analyze backup/restore from live cluster
analyze_backup_live() {
    if ! command -v oc >/dev/null 2>&1; then
        echo "oc command not found" >&2
        exit ${RC_SKIPPED}
    fi

    # Check if we can connect to cluster
    if ! oc whoami >/dev/null 2>&1; then
        echo "Cannot connect to OpenShift cluster" >&2
        exit ${RC_SKIPPED}
    fi

    local backup_issues=()

    # Check for etcd backup CronJob
    local etcd_backup_count
    etcd_backup_count=$(oc get cronjobs -n openshift-etcd --no-headers 2>/dev/null | grep -c "etcd-backup")

    if [[ ${etcd_backup_count} -eq 0 ]]; then
        backup_issues+=("No etcd backup CronJob found")
    fi

    # Check for OADP/Velero operator
    local oadp_namespaces=("openshift-adp" "velero")
    local oadp_found=false

    for ns in "${oadp_namespaces[@]}"; do
        if oc get namespace "${ns}" >/dev/null 2>&1; then
            oadp_found=true

            # Check OADP pods
            local failed_oadp_pods
            failed_oadp_pods=$(oc get pods -n "${ns}" --no-headers 2>/dev/null | grep -E "(velero|oadp|restic)" | grep -v "Running" | awk '{print $1": "$3}')

            if [[ -n ${failed_oadp_pods} ]]; then
                backup_issues+=("Failed OADP/Velero pods in ${ns}: ${failed_oadp_pods}")
            fi
        fi
    done

    if [[ ${oadp_found} == false ]]; then
        backup_issues+=("No OADP/Velero operator found")
    fi

    # Check for backup storage locations
    local bsl_issues=()
    for ns in "${oadp_namespaces[@]}"; do
        if oc get namespace "${ns}" >/dev/null 2>&1; then
            local bsl_count
            bsl_count=$(oc get backupstoragelocation -n "${ns}" --no-headers 2>/dev/null | wc -l)

            if [[ ${bsl_count} -eq 0 ]]; then
                bsl_issues+=("No backup storage locations in ${ns}")
            fi
        fi
    done

    if [[ ${#bsl_issues[@]} -gt 0 ]]; then
        backup_issues+=("${bsl_issues[@]}")
    fi

    # Check for recent backups
    local backup_schedules=()
    for ns in "${oadp_namespaces[@]}"; do
        if oc get namespace "${ns}" >/dev/null 2>&1; then
            local schedule_count
            schedule_count=$(oc get schedules -n "${ns}" --no-headers 2>/dev/null | wc -l)

            if [[ ${schedule_count} -gt 0 ]]; then
                backup_schedules+=("${ns}: ${schedule_count} backup schedules")
            fi
        fi
    done

    if [[ ${#backup_schedules[@]} -eq 0 ]]; then
        backup_issues+=("No backup schedules found")
    fi

    # Check for Volume Snapshot Classes
    local vsc_count
    vsc_count=$(oc get volumesnapshotclass --no-headers 2>/dev/null | wc -l)

    if [[ ${vsc_count} -eq 0 ]]; then
        backup_issues+=("No Volume Snapshot Classes found")
    fi

    # Check for persistent volume snapshots
    local pvs_count
    pvs_count=$(oc get volumesnapshot --all-namespaces --no-headers 2>/dev/null | wc -l)

    if [[ ${pvs_count} -eq 0 ]]; then
        backup_issues+=("No volume snapshots found")
    fi

    # Check for CSI drivers with snapshot capability
    local csi_snapshot_count
    csi_snapshot_count=$(oc get csidriver --no-headers 2>/dev/null | grep -c "true.*true")

    if [[ ${csi_snapshot_count} -eq 0 ]]; then
        backup_issues+=("No CSI drivers with snapshot capability found")
    fi

    # Check for recent successful backups
    local recent_backups=()
    for ns in "${oadp_namespaces[@]}"; do
        if oc get namespace "${ns}" >/dev/null 2>&1; then
            local successful_backups
            successful_backups=$(oc get backups -n "${ns}" --no-headers 2>/dev/null | grep "Completed" | wc -l)

            if [[ ${successful_backups} -gt 0 ]]; then
                recent_backups+=("${ns}: ${successful_backups} successful backups")
            fi
        fi
    done

    if [[ ${#recent_backups[@]} -eq 0 ]]; then
        backup_issues+=("No recent successful backups found")
    fi

    # Check for backup repository health
    local backup_repo_issues=()
    for ns in "${oadp_namespaces[@]}"; do
        if oc get namespace "${ns}" >/dev/null 2>&1; then
            local repo_health
            repo_health=$(oc get backuprepository -n "${ns}" --no-headers 2>/dev/null | grep -v "Ready" | wc -l)

            if [[ ${repo_health} -gt 0 ]]; then
                backup_repo_issues+=("${ns}: ${repo_health} unhealthy backup repositories")
            fi
        fi
    done

    if [[ ${#backup_repo_issues[@]} -gt 0 ]]; then
        backup_issues+=("${backup_repo_issues[@]}")
    fi

    # Check for restore operations
    local restore_issues=()
    for ns in "${oadp_namespaces[@]}"; do
        if oc get namespace "${ns}" >/dev/null 2>&1; then
            local failed_restores
            failed_restores=$(oc get restores -n "${ns}" --no-headers 2>/dev/null | grep -v "Completed" | wc -l)

            if [[ ${failed_restores} -gt 0 ]]; then
                restore_issues+=("${ns}: ${failed_restores} failed restores")
            fi
        fi
    done

    if [[ ${#restore_issues[@]} -gt 0 ]]; then
        backup_issues+=("${restore_issues[@]}")
    fi

    # Report findings
    if [[ ${#backup_issues[@]} -gt 0 ]]; then
        echo "Backup and restore issues found:" >&2
        printf '%s\n' "${backup_issues[@]}" >&2
        exit ${RC_SKIPPED}
    fi

    return 0
}

# Main execution
if is_mustgather; then
    analyze_backup_mustgather
    result=$?
else
    analyze_backup_live
    result=$?
fi

if [[ ${result} -eq 0 ]]; then
    exit "${RC_OKAY}"
else
    exit "${RC_FAILED}"
fi
