#!/bin/bash
# Copyright (C) 2021-2023 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.

# we can run this against fs snapshot or live system

# long_name: Tracebacks in services logs
# description: Report tracebacks in Containerized OpenStack services logs
# priority: 750

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

is_required_containerized

for log_file in $(ls ${RISU_ROOT}/var/log/containers/*/*.log); do
    [ -f "$log_file" ] || continue
    events=$(grep -i 'traceback' ${log_file} | grep -E -o '^([a-Z]+\ [0-9]+)|^([0-9\-]+)' | uniq -c | tail)
    if [[ -n ${events} ]]; then
        # to remove the ${RISU_ROOT} from the stderr.
        log_file=${log_file#${RISU_ROOT}}
        echo -e "$log_file:\n${events}\n" >&2
        flag=1
    fi
done

[[ "x$flag" == "x" ]] && exit ${RC_OKAY} || exit ${RC_FAILED}
