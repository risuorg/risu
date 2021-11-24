#!/bin/bash

# Copyright (C) 2018, 2021 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

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

# long_name: Provides output of lynis https://github.com/CISOfy/Lynis
# description: Reports lynis output https://github.com/CISOfy/Lynis
# priority: 100

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

if ! which lynis >/dev/null 2>&1; then
    echo "lynis (https://github.com/CISOfy/Lynis) support not found, exiting" >&2
    exit ${RC_SKIPPED}
fi

if [[ "x$RISU_LIVE" == "x0" ]]; then
    echo $"Lynis is not supported for non-live operations" >&2
    exit ${RC_SKIPPED}
elif [[ "x$RISU_LIVE" == "x1" ]]; then
    lynis audit system >&2
    exit ${RC_INFO}
fi
exit ${RC_OKAY}
