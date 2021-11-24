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

# long_name: Check RHEL system Lifecycle status
# description: Checks RHEL system Lifecycle status
# priority: 500
# kb: https://access.redhat.com/support/policy/updates/errata

OSBRAND=$(discover_osbrand)

declare -A RHELEOL
RHELEOL=(["6"]="2020-11-30"
    ["7"]="2024-06-30"
    ["8"]="2029-05-30")

declare -A RHELELS
RHELELS=(["5"]="2020-11-30"
    ["6"]="2024-06-30")

if [[ $OSBRAND != "rhel" ]]; then
    echo "RHEL OS required" >&2
    exit ${RC_SKIPPED}
else
    DR=$(discover_release)
    if [[ ${DR} -lt 5 ]]; then
        echo $"Your RHEL Release is already out of support phase: https://access.redhat.com/support/policy/updates/errata" >&2
        exit ${RC_FAILED}
    else
        if [[ ${RHELEOL[${DR}]} != "" ]]; then
            # Check first ELS
            if is_date_over_today "${RHELELS[${DR}]}"; then
                if is_date_over_today "${RHELEOL[${DR}]}"; then
                    if are_dates_diff_over 360 "${RHELEOL[${DR}]}" "$(LC_ALL=C LANG=C date)"; then
                        exit ${RC_OKAY}
                    else
                        echo $"Your system is within the year period to become unsupported outside of ELS" >&2
                        exit ${RC_INFO}
                    fi
                else
                    echo $"Your current RHEL release is unsupported unless you've ELS subscription" >&2
                    exit ${RC_FAILED}
                fi
            fi
            echo $"Your current RHEL release is unsupported" >&2
            exit ${RC_FAILED}
        else
            echo $"Your RHEL version has not defined EOL on file" >&2
            exit ${RC_INFO}
        fi
    fi
fi
exit ${RC_OKAY}
