#!/bin/bash
# Copyright (C) 2017   Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# long_name: Incompatible AggregateInstanceExtraSpecsFilter and ComputeCapabilitiesFilter
# description: Checks incompatible AggregateInstanceExtraSpecsFilter and ComputeCapabilitiesFilter in nova
# bugzilla: https://bugs.launchpad.net/nova/+bug/1279719
# priority: 600

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"


FILE="${CITELLUS_ROOT}/etc/nova/nova.conf"
is_required_file ${FILE}

RC=${RC_OKAY}
COUNT=$(grep "^scheduler_default_filters" "${FILE}"|grep ComputeCapabilitiesFilter|grep AggregateInstanceExtraSpecsFilter|wc -l)
if [[ ${COUNT} -ne 0 ]]; then
    echo $"Incompatible ComputeCapabilitiesFilter and AggregateInstanceExtraSpecsFilter in scheduler_default_filters at nova.conf" >&2
    RC=${RC_FAILED}
fi

exit ${RC}
