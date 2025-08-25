#!/bin/bash
# Copyright (C) 2021-2023 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

# long_name: Ceilometer expiration configuration
# description: Check for ceilometer expiration values
# priority: 750

# Actually run the check

RELEASE=$(discover_osp_version)

FILE=${RISU_ROOT}/etc/ceilometer/ceilometer.conf
is_required_file ${FILE}

RC=${RC_OKAY}
MORETHANONCE=$"is listed more than once on file"

# Check that ceilo polling central is listed (controllers only)
if is_process "polling-namespaces central"; then
    if [[ ${RELEASE} -gt 7 ]]; then
        strings="alarm_history_time_to_live event_time_to_live metering_time_to_live"
    else
        strings="time_to_live"
    fi
    for string in ${strings}; do
        # check for string
        if ! is_lineinfile ^${string} ${FILE}; then
            echo "$string missing on file" >&2
            RC=${RC_FAILED}
        elif [[ $(grep -c -e ^${string} ${FILE}) -gt 1 ]]; then
            echo -n "$string" >&2
            echo " $MORETHANONCE" >&2
            RC=${RC_FAILED}
        else
            if [[ $(grep -e ^${string} ${FILE} | cut -d "=" -f2) -le 0 ]]; then
                echo $"ceilometer.conf setting must be updated:" >&2
                RC=${RC_FAILED}
                grep -e ^${string} ${FILE} >&2
            fi
        fi
    done
else
    echo "Works only on controllers" >&2
    RC=${RC_SKIPPED}
fi

exit ${RC}
