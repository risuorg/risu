#!/bin/bash

# Copyright (C) 2017, 2018, 2020, 2021, 2023 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

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

# long_name: reports ram available
# description: reports ram available
# priority: 930

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

if [[ "x$RISU_LIVE" == "x0" ]]; then
    MEMORY=$(awk '/Mem/ {print $2}' ${RISU_ROOT}/free)
else
    MEMORY=$(LANG=C free | awk '/Mem/ {print $2}')
fi

echo "$((MEMORY / 1024))" >&2
exit ${RC_OKAY}
