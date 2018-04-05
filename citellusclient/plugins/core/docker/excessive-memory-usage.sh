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

# we can run this on fs snapshot or live system

# long_name: Checks for high mem usage docker version
# description: Some docker versions have excessive memory usage
# priority: 700

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

is_required_rpm docker

if is_rpm_over docker docker-1.12.6-16.el7.x86_64; then
    if is_rpm_over docker docker-1.12.6-48; then
        exit ${RC_OKAY}
    fi
    echo $"docker might have high memory consumption" >&2
    exit ${RC_FAILED}
fi
exit ${RC_OKAY}
