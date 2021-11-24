#!/bin/bash

# Copyright (C) 2018, 2020, 2021 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

# This program is Free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

# long_name: Check RH OpenStack system Lifecycle status
# description: Checks RH OpenStack system Lifecycle status
# priority: 500
# kb: https://access.redhat.com/support/policy/updates/openstack/platform

OSBRAND=$(discover_osbrand)

declare -A RHOSEOL
RHOSEOL=(["8"]="2019-04-20"
    ["9"]="2019-08-24"
    ["10"]="2019-12-16"
    ["11"]="2018-05-18"
    ["12"]="2018-12-13"
    ["13"]="2021-06-27"
    ["14"]="2020-01-10"
    ["15"]="2020-09-19"
    ["16"]="2024-05-30")

if [[ $OSBRAND != "rhel" ]]; then
    echo "RHEL OS required" >&2
    exit ${RC_SKIPPED}
else
    DR=$(discover_osp_version)
    if [[ ${DR} -eq 0 ]]; then
        echo "Non OSP host" >&2
        exit ${RC_SKIPPED}
    fi
    if [[ ${DR} -lt 8 ]]; then
        echo $"Your RHOS Release is already out of support phase: https://access.redhat.com/support/policy/updates/openstack/platform" >&2
        exit ${RC_FAILED}
    else
        if [[ ${RHOSEOL[${DR}]} != "" ]]; then
            if is_date_over_today "${RHOSEOL[${DR}]}"; then
                if are_dates_diff_over 360 "${RHOSEOL[${DR}]}" "$(LC_ALL=C LANG=C date)"; then
                    exit ${RC_OKAY}
                else
                    echo $"Your system is within the year period to become unsupported" >&2
                    exit ${RC_INFO}
                fi
            fi
            echo $"Your current RHOS release is unsupported" >&2
            exit ${RC_FAILED}
        else
            echo $"Your OSP version has not defined EOL on file" >&2
            exit ${RC_INFO}
        fi
    fi
fi
exit ${RC_OKAY}
