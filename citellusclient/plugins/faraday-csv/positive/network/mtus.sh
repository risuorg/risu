#!/bin/bash

# Copyright (C) 2018 Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)

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

# long_name: Metadata generator for MTU's for nics
# description: Generates keypairs for MTU's for nics
# priority: 800

# Code for generating items for faraday-CSV
if [[ "x$1" == "x_items_" ]]; then
    echo 'eth0' >&2
    exit 0
fi

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

is_required_file "${CITELLUS_ROOT}/etc/sysconfig/iptables"
MD5SUM=$(cat "${CITELLUS_ROOT}/etc/sysconfig/iptables" | sed '1d;$d'| md5sum|awk '{print $1}')

echo "${MD5SUM}" >&2
exit ${RC_OKAY}
