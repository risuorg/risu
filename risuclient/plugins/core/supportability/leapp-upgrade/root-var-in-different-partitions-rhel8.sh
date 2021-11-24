#!/bin/bash

# Copyright (C) 2019, 2020, 2021 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

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

# long_name: Report / and /var in different partions not valid for Leapp upgrade
# description: Report / and /var in different partions not valid for Leapp upgrade
# priority: 200
# kb: https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html-single/upgrading_to_rhel_8/index#requirements-upgrading-to-rhel-8

OS=$(discover_os)

if [[ ${OSBRAND} != "rhel" ]]; then
    echo "RHEL OS required" >&2
    exit ${RC_SKIPPED}
else
    DR=$(discover_release)
    if [[ ${DR} == "7" ]]; then
        if [[ "x$RISU_LIVE" == "x0" ]]; then
            is_required_file "${RISU_ROOT}/df"
            lines=$(cat "${RISU_ROOT}/df" | awk '{print $6}' | awk '/\/$/ || /\/var$/' | sort -u | wc -l)
        elif [[ "x$RISU_LIVE" == "x1" ]]; then
            lines=$(df / /var | awk '{print $6}' | awk '/\/$/ || /\/var$/' | sort -u | wc -l)
        fi
        if [[ ${lines} -gt 2 ]]; then
            echo "Seems that / and /var are in different devices which affects Leapp upgrade from RHEL7 to RHEL8" >&2
            echo ${RC_INFO}
        fi
    fi
fi

exit {$RC_OKAY}
