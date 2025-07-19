#!/bin/bash
# Copyright (C) 2021-2023 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

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

# long_name: Perf events enabled in nova
# description: Checks if perf events are enabled in nova
# bugzilla:
# priority: 750
# kb: https://access.redhat.com/solutions/3408891

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

is_required_file "${RISU_ROOT}/etc/nova/nova.conf"

# Find release
RELEASE=$(discover_osp_version)

if [[ "x$(iniparser "${RISU_ROOT}/etc/nova/nova.conf" libvirt enabled_perf_events)" != "x" ]]; then
    echo $"perf events enabled in nova" >&2
    exit ${RC_FAILED}
fi

exit ${RC_OKAY}
