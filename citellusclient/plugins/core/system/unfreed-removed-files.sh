#!/bin/bash

# Copyright (C) 2018 John Devereux (john_devereux@yahoo.com) at sumsos
# Modifications by Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)

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

# long_name: Checks for removed files still used by processes
# priority: 600
# description: This plugin reports files that have been removed but not freed

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

lsoffile="$(mktemp)"
trap "/bin/rm ${lsoffile}" EXIT

if [[ "x$CITELLUS_LIVE" = "x0" ]]; then
    for FILE in "sos_commands/filesys/lsof_-b_M_-n_-l" "lsof"; do
        [ -f "${CITELLUS_ROOT}/${FILE}" ] && cat "${CITELLUS_ROOT}/${FILE}" |grep '(deleted)' > ${lsoffile}
    done
else
    LANG=C lsof 2>&1|grep '(deleted)' > ${lsoffile}
fi

NOFILES=$(cat ${lsoffile}  |grep '(deleted)'|sed 's/\s\s*/ /g'|cut -d ' ' -f 8|wc -l)
SZFILES=$(echo $(cat lsof  |grep '(deleted)'|sed 's/\s\s*/ /g'|cut -d ' ' -f 8-9|sort|uniq|awk '{print $2" "$1}'|grep ^/|awk '{print $2}'|tr "\n" "+")0|bc)

if [[ "${NOFILES}" -gt 99 ]] || [[ "${SZFILES}" -ge "1000000000" ]]; then
    echo "A total of $NOFILES deleted files are consuming $SZFILES bytes on disk" >&2
    exit ${RC_FAILED}
fi

exit ${RC_OKAY}
