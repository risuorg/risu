#!/bin/bash

# Copyright (C) 2018, 2020, 2021 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

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

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

# long_name: Check Fedora system Lifecycle status
# description: Checks Fedora system Lifecycle status
# priority: 500
# kb: https://fedoraproject.org/wiki/Fedora_Release_Life_Cycle

# Fedora 27 will be maintained until 1 month after the release of Fedora 29.
# Fedora 28 will be maintained until 1 month after the release of Fedora 30.

OSBRAND=$(discover_osbrand)

declare -A fedoraRD
fedoraRD=(["27"]="2017-11-14"
    ["28"]="2018-05-01"
    ["29"]="2018-10-23"
    ["30"]="2019-04-30"
    ["31"]="2019-10-31")

if [[ $OSBRAND != "fedora" ]]; then
    echo "Fedora OS required" >&2
    exit ${RC_SKIPPED}
else
    FR=$(discover_release)
    if [[ ${FR} -lt 27 ]]; then
        echo $"Your Fedora Release is already out of support phase: https://fedoraproject.org/wiki/End_of_life" >&2
        exit ${RC_FAILED}
    else
        # Check dates for release + 2
        if [[ ${fedoraRD[FR + 2]} == "" ]]; then
            # Next release is not yet defined, exit as OK
            exit ${RC_OKAY}
        else
            # Fedora is supported until 30 days after release of next two versions
            if is_date_over_today "${fedoraRD[FR + 2]}"; then
                if are_dates_diff_over 210 "${fedoraRD[FR + 2]}" "$(LC_ALL=C LANG=C date)"; then
                    exit ${RC_OKAY}
                else
                    echo $"Your system is within the half-year period to become unsupported" >&2
                    exit ${RC_INFO}
                fi
            fi
            echo $"Your current Fedora release is unsupported" >&2
            exit ${RC_FAILED}
        fi
    fi

fi
exit ${RC_OKAY}
