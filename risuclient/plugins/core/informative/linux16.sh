#!/bin/bash

# Copyright (C) 2024 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

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

# long_name: Detects if system is using linux16 and/or initd16 instead of regular descriptions
# description: Reports if system is using linux16 or initrd16
# priority: 100
# kb:

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

MYFILE="${RISU_ROOT}/etc/grub2.cfg"

is_required_file ${MYFILE}

RC=${RC_OKAY}

if is_lineinfile ^linux16.* ${MYFILE}; then
    RC=${RC_INFO}
    echo "linux16 entry detected in ${MYFILE}" >&2
fi
if is_lineinfile ^initrd16.* ${MYFILE}; then
    RC=${RC_INFO}
    echo "initrd16 entry detected in ${MYFILE}" >&2
fi
exit ${RC}
