#!/bin/bash

# Copyright (C) 2017   Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)

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

# long_name: Package rollback, undo or redo
# description: this plugin checks in yum history for undo/rollback/redo
# priority: 300

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

if [[ ${CITELLUS_LIVE} = 0 ]]; then
    FILE="${CITELLUS_ROOT}/sos_commands/yum/yum_history"
else
    FILE=$(mktemp)
    trap "rm ${FILE}" EXIT
    yum history > ${FILE}
fi

is_required_file ${FILE}
flag=0

if is_lineinfile undo ${FILE}; then
    flag=1
fi

if is_lineinfile redo ${FILE}; then
    flag=1
fi

if is_lineinfile rollback ${FILE}; then
    flag=1
fi

if [[ ${flag} -eq '1' ]]; then
    echo $"detected undo/redo/rollback yum operations" >&2
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
