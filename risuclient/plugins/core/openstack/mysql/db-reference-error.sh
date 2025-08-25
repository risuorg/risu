#!/bin/bash
# Copyright (C) 2021-2023 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

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

# we can run this against fs snapshot or live system

# long_name: DBReferenceError in services logs
# description: Report DBReferenceError in OpenStack services logs
# priority: 750

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

if [[ "x$RISU_LIVE" == "x1" ]]; then
    log_files=$(
        for i in $(rpm -qa | sed -n -r -e 's/^openstack-([a-z]*)-.*$/\1/p' | sort | uniq); do
            ls /var/log/${i}/*.log 2>/dev/null | grep '/var/log/[^/]*/[^/]*\.log'
        done
    )
elif [[ "x$RISU_LIVE" == "x0" ]]; then
    is_required_file "${RISU_ROOT}/installed-rpms"
    log_files=$(
        for i in $(sed -n -r -e 's/^openstack-([a-z]*)-.*$/\1/p' ${RISU_ROOT}/installed-rpms | sort | uniq); do
            ls ${RISU_ROOT}/var/log/${i}/*.log 2>/dev/null | grep '/var/log/[^/]*/[^/]*\.log'
        done
    )
fi

for log_file in ${log_files}; do
    [ -f "$log_file" ] || continue
    wc=$(grep -i 'DBReferenceError' ${log_file} | wc -l)
    if [[ ${wc} -gt 0 ]]; then
        # to remove the ${RISU_ROOT} from the stderr.
        log_file=${log_file#${RISU_ROOT}}
        echo "$log_file (${wc} times)" >&2
        flag=1
    fi
done
[[ "x$flag" == "x" ]] && exit ${RC_OKAY} || exit ${RC_FAILED}
