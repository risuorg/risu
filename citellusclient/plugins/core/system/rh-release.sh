#!/bin/bash

# Copyright (C) 2017   Robin Černín (rcernin@redhat.com)

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

# check redhat-release

# long_name: RHEL release
# description: Detects RHEL release
# priority: 200

if [[ ! -f "${CITELLUS_ROOT}/etc/redhat-release" ]]; then
    echo "this is not RHEL distribution" >&2
    exit ${RC_FAILED}
else
    cat "${CITELLUS_ROOT}/etc/redhat-release" >&2
    exit ${RC_OKAY}
fi

