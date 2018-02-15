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

# this can run against live and also any sort of snapshot of the filesystem

# long_name: Mismatch between nova host and ceilometer host
# description: Checks missconfigured host in nova vs ceilometer
# priority: 500

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

if ! is_process nova-compute; then
    echo $"works only on compute node" >&2
    exit ${RC_SKIPPED}
fi

is_required_file "${CITELLUS_ROOT}/etc/nova/nova.conf"
is_required_file "${CITELLUS_ROOT}/etc/ceilometer/ceilometer.conf"

NOVAHOST=$(awk -F "=" '/^host/ {gsub (" ", "", $0); print $2}' ${CITELLUS_ROOT}/etc/nova/nova.conf)
CEILOMETERHOST=$(awk -F "=" '/^host/ {gsub (" ", "", $0); print $2}' ${CITELLUS_ROOT}/etc/ceilometer/ceilometer.conf)

if [[ "$CEILOMETERHOST" != "$NOVAHOST" ]]; then
    echo $"ceilometer and nova compute host are out of sync." >&2
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
