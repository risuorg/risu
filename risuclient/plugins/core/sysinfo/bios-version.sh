#!/bin/bash

# Copyright (C) 2017 Robin Černín <cerninr@gmail.com>
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

# long_name: reports BIOS version
# description: reports BIOS version
# priority: 100

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

if [[ "x$RISU_LIVE" == "x0" ]]; then
    is_required_file ${RISU_ROOT}/dmidecode
    python ${RISU_BASE}/tools/dmidecode.py <${RISU_ROOT}/dmidecode | grep ^BIOS >&2
else
    dmidecode | python ${RISU_BASE}/tools/dmidecode.py | grep ^BIOS >&2
fi

exit ${RC_OKAY}
