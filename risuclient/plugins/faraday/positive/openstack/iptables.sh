#!/bin/bash

# Copyright (C) 2018 Robin Černín <cerninr@gmail.com>
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

# we can run this against fs snapshot or live system

# long_name: Network iptables consistency
# description: Checks for iptables consitency
# path: ${RISU_ROOT}/etc/sysconfig/iptables
# priority: 800

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

is_required_file "${RISU_ROOT}/etc/sysconfig/iptables"
MD5SUM=$(sed '1d;$d' "${RISU_ROOT}/etc/sysconfig/iptables" | md5sum | awk '{print $1}')

echo "${MD5SUM}" >&2
exit ${RC_OKAY}
