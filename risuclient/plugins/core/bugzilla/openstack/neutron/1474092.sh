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

# long_name: Mismatch between neutron host and hostname
# description: Checks for wrong host definition on neutron.conf
# bugzilla: https://bugzilla.redhat.com/show_bug.cgi?id=1474092
# priority: 700

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

is_required_file "${RISU_ROOT}/etc/neutron/neutron.conf"

if [[ "$(iniparser "${RISU_ROOT}/etc/neutron/neutron.conf" DEFAULT host)" == "localhost" ]]; then
    echo $"neutron.conf https://bugzilla.redhat.com/show_bug.cgi?id=1474092" >&2
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
