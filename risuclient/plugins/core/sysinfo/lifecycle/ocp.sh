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

# long_name: Check RH OpenShift system Lifecycle status
# description: Checks RH OpenShift system Lifecycle status
# priority: 500
# kb: https://access.redhat.com/support/policy/updates/openshift

OSBRAND=$(discover_osbrand)

declare -A OCPEOL
OCPEOL=(["3.0"]="2018-11-30"
    ["3.1"]="2018-11-30"
    ["3.2"]="2019-01-31"
    ["3.3"]="2019-01-31"
    ["3.4"]="2019-04-30"
    ["3.5"]="2019-04-30"
    ["3.6"]="2019-07-31"
    ["3.7"]="2019-07-31"
    ["3.9"]="2019-10-31"
    ["3.10"]="2019-10-31")

if [[ $OSBRAND != "rhel" ]]; then
    echo "RHEL OS required" >&2
    exit ${RC_SKIPPED}
else
    DR=$(discover_ocp_version)
    if [[ ${DR} == "0" ]]; then
        echo "Non OCP host" >&2
        exit ${RC_SKIPPED}
    fi
    if [[ ${OCPEOL[${DR}]} != "" ]]; then
        if is_date_over_today "${OCPEOL[${DR}]}"; then
            if are_dates_diff_over 180 "${OCPEOL[${DR}]}" "$(LC_ALL=C LANG=C date)"; then
                exit ${RC_OKAY}
            else
                echo $"Your OCP version is within the half-year period to become unsupported" >&2
                exit ${RC_INFO}
            fi
        else
            echo $"Your OCP version is unsupported" >&2
            exit ${RC_FAILED}
        fi
    else
        echo $"Your OCP version has not defined EOL on file" >&2
        exit ${RC_INFO}
    fi
fi
exit ${RC_OKAY}
