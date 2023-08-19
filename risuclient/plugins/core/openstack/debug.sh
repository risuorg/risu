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

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

# long_name: Services debug configuration
# description: Check if services are configured for logging in DEBUG level
# priority: 100

# if we are running against live system or fs snapshot

if [[ "x$RISU_LIVE" == "x1" ]]; then
    config_files=$(rpm -qa -c 'openstack-*' | grep '/etc/[^/]*/[^/]*\.conf')
elif [[ "x$RISU_LIVE" == "x0" ]]; then
    is_required_file "${RISU_ROOT}/installed-rpms"
    config_files=$(
        for i in $(sed -n -r -e 's/^openstack-([a-z]*)-.*$/\1/p' ${RISU_ROOT}/installed-rpms | sort | uniq); do
            ls ${RISU_ROOT}/etc/${i}/*.conf 2>/dev/null | grep '/etc/[^/]*/[^/]*\.conf'
        done
    )
    [ -e "${RISU_ROOT}/etc/openstack-dashboard/local_settings" ] && config_files+=" ${RISU_ROOT}/etc/openstack-dashboard/local_settings"
fi

for config_file in ${config_files}; do
    [ -f "$config_file" ] || continue
    if [[ "$(iniparser "$config_file" DEFAULT debug)" == "true" ]]; then
        # to remove the ${RISU_ROOT} from the stderr.
        config_file=${config_file#${RISU_ROOT}}
        echo "enabled in $config_file" >&2
        flag=1
    else
        config_file=${config_file#${RISU_ROOT}}
        echo "disabled in $config_file" >&2
    fi
done
[[ "x$flag" == "x1" ]] && exit ${RC_FAILED} || exit ${RC_OKAY}
