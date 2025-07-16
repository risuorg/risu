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

# long_name: OpenShift Builds and CI/CD Validation Check
# description: Validates OpenShift build and CI/CD configurations
# priority: 740

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

is_required_file "${RISU_BASE}/common-functions.sh"

# Function to check if we're analyzing a Must Gather
is_mustgather() {
    [[ ${RISU_LIVE} != "1" ]] && [[ -d "namespaces" || -d "cluster-scoped-resources" ]]
}

# Function to analyze builds from Must Gather
analyze_builds_mustgather() {
    local builds_issues=()

    # Check for BuildConfigs and Builds across namespaces
    local failed_builds=()
    local stale_builds=()

    if [[ -d "namespaces" ]]; then
        for ns_dir in namespaces/*; do
            if [[ -d ${ns_dir} ]]; then
                local namespace=$(basename "${ns_dir}")

                # Check BuildConfigs
                local buildconfigs_file="${ns_dir}/build.openshift.io/buildconfigs.yaml"
                if [[ -f ${buildconfigs_file} ]]; then
                    local bc_count
                    bc_count=$(grep -c "^[[:space:]]*name:" "${buildconfigs_file}" 2>/dev/null || echo 0)

                    if [[ ${bc_count} -gt 0 ]]; then
                        # Check Builds
                        local builds_file="${ns_dir}/build.openshift.io/builds.yaml"
                        if [[ -f ${builds_file} ]]; then
                            local current_build=""
                            local build_phase=""

                            while IFS= read -r line; do
                                if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*(.+)$ ]]; then
                                    current_build="${BASH_REMATCH[1]}"
                                elif [[ ${line} =~ ^[[:space:]]*phase:[[:space:]]*(.+)$ ]]; then
                                    build_phase="${BASH_REMATCH[1]}"

                                    if [[ ${build_phase} == "Failed" ]]; then
                                        failed_builds+=("${namespace}/${current_build}")
                                    elif [[ ${build_phase} == "Pending" ]]; then
                                        stale_builds+=("${namespace}/${current_build}")
                                    fi
                                fi
                            done <"${builds_file}"
                        fi
                    fi
                fi
            fi
        done
    fi

    if [[ ${#failed_builds[@]} -gt 0 ]]; then
        builds_issues+=("Failed builds: ${failed_builds[*]}")
    fi

    if [[ ${#stale_builds[@]} -gt 0 ]]; then
        builds_issues+=("Stale/pending builds: ${stale_builds[*]}")
    fi

    # Check for Tekton Pipelines
    local pipeline_issues=()
    if [[ -d "namespaces" ]]; then
        for ns_dir in namespaces/*; do
            if [[ -d ${ns_dir} ]]; then
                local namespace=$(basename "${ns_dir}")

                # Check Pipelines
                local pipelines_file="${ns_dir}/tekton.dev/pipelines.yaml"
                if [[ -f ${pipelines_file} ]]; then
                    local pipeline_count
                    pipeline_count=$(grep -c "^[[:space:]]*name:" "${pipelines_file}" 2>/dev/null || echo 0)

                    if [[ ${pipeline_count} -gt 0 ]]; then
                        # Check PipelineRuns
                        local pipelineruns_file="${ns_dir}/tekton.dev/pipelineruns.yaml"
                        if [[ -f ${pipelineruns_file} ]]; then
                            local current_run=""
                            local run_status=""

                            while IFS= read -r line; do
                                if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*(.+)$ ]]; then
                                    current_run="${BASH_REMATCH[1]}"
                                elif [[ ${line} =~ ^[[:space:]]*reason:[[:space:]]*(.+)$ ]]; then
                                    run_status="${BASH_REMATCH[1]}"

                                    if [[ ${run_status} == "Failed" ]]; then
                                        pipeline_issues+=("${namespace}/${current_run}: Failed")
                                    elif [[ ${run_status} == "PipelineRunTimeout" ]]; then
                                        pipeline_issues+=("${namespace}/${current_run}: Timeout")
                                    fi
                                fi
                            done <"${pipelineruns_file}"
                        fi
                    fi
                fi
            fi
        done
    fi

    if [[ ${#pipeline_issues[@]} -gt 0 ]]; then
        builds_issues+=("Pipeline issues: ${pipeline_issues[*]}")
    fi

    # Check for Jenkins
    local jenkins_issues=()
    if [[ -d "namespaces" ]]; then
        for ns_dir in namespaces/*; do
            if [[ -d ${ns_dir} ]]; then
                local namespace=$(basename "${ns_dir}")
                local pods_file="${ns_dir}/core/pods.yaml"

                if [[ -f ${pods_file} ]]; then
                    local jenkins_pods=()
                    local current_pod=""
                    local pod_phase=""

                    while IFS= read -r line; do
                        if [[ ${line} =~ ^[[:space:]]*name:[[:space:]]*(.+)$ ]]; then
                            current_pod="${BASH_REMATCH[1]}"
                        elif [[ ${line} =~ ^[[:space:]]*phase:[[:space:]]*(.+)$ ]]; then
                            pod_phase="${BASH_REMATCH[1]}"

                            if [[ ${current_pod} =~ jenkins ]]; then
                                jenkins_pods+=("${current_pod}")
                                if [[ ${pod_phase} != "Running" ]]; then
                                    jenkins_issues+=("${namespace}/${current_pod}: ${pod_phase}")
                                fi
                            fi
                        fi
                    done <"${pods_file}"
                fi
            fi
        done
    fi

    if [[ ${#jenkins_issues[@]} -gt 0 ]]; then
        builds_issues+=("Jenkins issues: ${jenkins_issues[*]}")
    fi

    # Check for Image Streams
    local imagestream_issues=()
    if [[ -d "namespaces" ]]; then
        for ns_dir in namespaces/*; do
            if [[ -d ${ns_dir} ]]; then
                local namespace=$(basename "${ns_dir}")
                local is_file="${ns_dir}/image.openshift.io/imagestreams.yaml"

                if [[ -f ${is_file} ]]; then
                    local is_count
                    is_count=$(grep -c "^[[:space:]]*name:" "${is_file}" 2>/dev/null || echo 0)

                    if [[ ${is_count} -eq 0 ]]; then
                        imagestream_issues+=("${namespace}: No ImageStreams found")
                    fi
                fi
            fi
        done
    fi

    if [[ ${#imagestream_issues[@]} -gt 5 ]]; then
        builds_issues+=("Many namespaces without ImageStreams: ${#imagestream_issues[@]} namespaces")
    fi

    # Report findings
    if [[ ${#builds_issues[@]} -gt 0 ]]; then
        echo "Builds and CI/CD issues found:" >&2
        printf '%s\n' "${builds_issues[@]}" >&2
        exit ${RC_SKIPPED}
    fi

    return 0
}

# Function to analyze builds from live cluster
analyze_builds_live() {
    if ! command -v oc >/dev/null 2>&1; then
        echo "oc command not found" >&2
        exit ${RC_SKIPPED}
    fi

    # Check if we can connect to cluster
    if ! oc whoami >/dev/null 2>&1; then
        echo "Cannot connect to OpenShift cluster" >&2
        exit ${RC_SKIPPED}
    fi

    local builds_issues=()

    # Check for failed builds
    local failed_builds
    failed_builds=$(oc get builds --all-namespaces --no-headers 2>/dev/null | grep Failed | awk '{print $1"/"$2}')

    if [[ -n ${failed_builds} ]]; then
        builds_issues+=("Failed builds: ${failed_builds}")
    fi

    # Check for stale/pending builds
    local stale_builds
    stale_builds=$(oc get builds --all-namespaces --no-headers 2>/dev/null | grep Pending | awk '{print $1"/"$2}')

    if [[ -n ${stale_builds} ]]; then
        builds_issues+=("Stale/pending builds: ${stale_builds}")
    fi

    # Check BuildConfigs without recent builds
    local bc_without_builds
    bc_without_builds=$(oc get buildconfig --all-namespaces --no-headers 2>/dev/null | while read -r ns bc _; do
        if [[ $(oc get builds -n "${ns}" -l buildconfig="${bc}" --no-headers 2>/dev/null | wc -l) -eq 0 ]]; then
            echo "${ns}/${bc}" >&2
        fi
    done | head -10)

    if [[ -n ${bc_without_builds} ]]; then
        builds_issues+=("BuildConfigs without builds: ${bc_without_builds}")
    fi

    # Check for Tekton Pipelines
    local pipeline_issues
    pipeline_issues=$(oc get pipelineruns --all-namespaces --no-headers 2>/dev/null | grep -E "(Failed|PipelineRunTimeout)" | awk '{print $1"/"$2": "$3}')

    if [[ -n ${pipeline_issues} ]]; then
        builds_issues+=("Pipeline issues: ${pipeline_issues}")
    fi

    # Check Tekton operator
    local tekton_operator_status
    tekton_operator_status=$(oc get subscription -n openshift-operators --no-headers 2>/dev/null | grep -E "(tekton|pipelines)" | grep -v "AtLatestKnown" | awk '{print $1": "$3}')

    if [[ -n ${tekton_operator_status} ]]; then
        builds_issues+=("Tekton operator issues: ${tekton_operator_status}")
    fi

    # Check for Jenkins
    local jenkins_issues
    jenkins_issues=$(oc get pods --all-namespaces --no-headers 2>/dev/null | grep jenkins | grep -v "Running" | awk '{print $1"/"$2": "$3}')

    if [[ -n ${jenkins_issues} ]]; then
        builds_issues+=("Jenkins issues: ${jenkins_issues}")
    fi

    # Check for Image Streams
    local imagestream_count
    imagestream_count=$(oc get imagestream --all-namespaces --no-headers 2>/dev/null | wc -l)

    if [[ ${imagestream_count} -eq 0 ]]; then
        builds_issues+=("No ImageStreams found")
    fi

    # Check for S2I builder images
    local s2i_images_count
    s2i_images_count=$(oc get imagestream -n openshift --no-headers 2>/dev/null | grep -c "s2i")

    if [[ ${s2i_images_count} -eq 0 ]]; then
        builds_issues+=("No S2I builder images found")
    fi

    # Check for build pods
    local build_pods
    build_pods=$(oc get pods --all-namespaces --no-headers 2>/dev/null | grep -E "build.*Error" | awk '{print $1"/"$2": "$3}')

    if [[ -n ${build_pods} ]]; then
        builds_issues+=("Build pods with errors: ${build_pods}")
    fi

    # Check for webhooks
    local bc_with_webhooks
    bc_with_webhooks=$(oc get buildconfig --all-namespaces -o json 2>/dev/null | jq -r '.items[] | select(.spec.triggers[]?.type == "GitHub" or .spec.triggers[]?.type == "GitLab") | .metadata.namespace + "/" + .metadata.name' 2>/dev/null | wc -l)

    if [[ ${bc_with_webhooks} -eq 0 ]]; then
        builds_issues+=("No BuildConfigs with webhooks found")
    fi

    # Check for build resources
    local bc_without_resources
    bc_without_resources=$(oc get buildconfig --all-namespaces -o json 2>/dev/null | jq -r '.items[] | select(.spec.resources == null or .spec.resources == {}) | .metadata.namespace + "/" + .metadata.name' 2>/dev/null | wc -l)

    if [[ ${bc_without_resources} -gt 10 ]]; then
        builds_issues+=("Many BuildConfigs without resource limits: ${bc_without_resources}")
    fi

    # Check for build strategy
    local binary_builds
    binary_builds=$(oc get buildconfig --all-namespaces -o json 2>/dev/null | jq -r '.items[] | select(.spec.strategy.type == "Binary") | .metadata.namespace + "/" + .metadata.name' 2>/dev/null | wc -l)

    if [[ ${binary_builds} -gt 0 ]]; then
        builds_issues+=("Binary build strategies found: ${binary_builds}")
    fi

    # Check for build logs retention
    local build_retention_issues
    build_retention_issues=$(oc get buildconfig --all-namespaces -o json 2>/dev/null | jq -r '.items[] | select(.spec.successfulBuildsHistoryLimit == null or .spec.failedBuildsHistoryLimit == null) | .metadata.namespace + "/" + .metadata.name' 2>/dev/null | wc -l)

    if [[ ${build_retention_issues} -gt 0 ]]; then
        builds_issues+=("BuildConfigs without build history limits: ${build_retention_issues}")
    fi

    # Check for TaskRuns
    local taskrun_issues
    taskrun_issues=$(oc get taskruns --all-namespaces --no-headers 2>/dev/null | grep -E "(Failed|TaskRunTimeout)" | awk '{print $1"/"$2": "$3}')

    if [[ -n ${taskrun_issues} ]]; then
        builds_issues+=("TaskRun issues: ${taskrun_issues}")
    fi

    # Report findings
    if [[ ${#builds_issues[@]} -gt 0 ]]; then
        echo "Builds and CI/CD issues found:" >&2
        printf '%s\n' "${builds_issues[@]}" >&2
        exit ${RC_SKIPPED}
    fi

    return 0
}

# Main execution
if is_mustgather; then
    analyze_builds_mustgather
    result=$?
else
    analyze_builds_live
    result=$?
fi

if [[ ${result} -eq 0 ]]; then
    exit "${RC_OKAY}"
else
    exit "${RC_FAILED}"
fi
