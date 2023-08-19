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

# we can run this on fs snapshot

# long_name: Services debug configuration
# description: Check OpenStack services debug configuration in containers
# priority: 200

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

is_required_containerized

CONFIG_FOLDER="${RISU_ROOT}/var/lib/config-data/puppet-generated"

if [[ "x$RISU_LIVE" == "x1" ]]; then
    echo $"works only against fs snapshot"
    exit ${RC_SKIPPED}
elif [[ "x$RISU_LIVE" == "x0" ]]; then
    containers=$(
        for directory in ${CONFIG_FOLDER}/*; do
            if [[ -d ${directory} ]]; then
                echo ${directory} | sed -n -r -e 's_^.*puppet-generated/([a-z].*).*$_\1_p' | sort | uniq
            fi
        done
    )
    config_files=$(
        for i in ${containers}; do
            ls ${CONFIG_FOLDER}/${i}/etc/${i}/*.conf 2>/dev/null | grep '/etc/[^/]*/[^/]*\.conf'
        done
    )
fi

for config_file in ${config_files}; do
    [ -f "$config_file" ] || continue
    if [[ "$(iniparser "$config_file" DEFAULT debug)" == "true" ]]; then
        # to remove the ${CONFIG_FOLDER} from the stderr.
        config_file=${config_file#${CONFIG_FOLDER}}
        echo "enabled in $config_file" >&2
        flag=1
    else
        config_file=${config_file#${CONFIG_FOLDER}}
        echo "disabled in $config_file" >&2
    fi
done
[[ "x$flag" == "x1" ]] && exit ${RC_FAILED} || exit ${RC_OKAY}
