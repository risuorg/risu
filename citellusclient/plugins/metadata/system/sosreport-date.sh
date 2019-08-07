#!/bin/bash

# Copyright (C) 2018 Robin Černín <cerninr@gmail.com>
# Copyright (C) 2018 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>


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

# long_name: reports date for sosreport
# description: Sets sosreport date metadata

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

if [[ ${CITELLUS_LIVE} -eq 0 ]]; then
    sosdate=$(LC_ALL=C LANG=C date -d "$(cat ${CITELLUS_ROOT}/date)" +%Y-%m-%d)
else
    sosdate=$(LC_ALL=C LANG=C TZ='UTC' date +%Y-%m-%d)
fi

# Fill metadata 'sosreport-date' to value
echo "sosreport-date"
echo ${sosdate} >&2
exit ${RC_OKAY}
