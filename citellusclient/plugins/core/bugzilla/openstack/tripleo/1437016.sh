#!/bin/bash

# Copyright (C) 2018  Martin Schuppert (mschuppert@redhat.com)

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

# long_name: Overcloud update stuck in progress
# description: 'openstack overcloud update' loops on 'IN_PROGRESS' and times out
# bugzilla: https://bugzilla.redhat.com/show_bug.cgi?id=1437016
# priority: 600

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

exitoutdated(){
    echo $"outdated openstack-tripleo-common causes IN_PROGRESS loops: https://bugzilla.redhat.com/show_bug.cgi?id=1437016" >&2
}

RELEASE=$(discover_osp_version)
if [[ "${RELEASE}" -eq "8" ]]; then
    exitoutdated
    # openstack-tripleo-common needs to be 0.3.1-5 or later
    is_required_rpm_over openstack-tripleo-common openstack-tripleo-common-0.3.1-5.el7ost
elif [[ "${RELEASE}" -eq "9" ]]; then
    exitoutdated
    # openstack-tripleo-common needs to be 2.0.0-11 or later
    is_required_rpm_over openstack-tripleo-common openstack-tripleo-common-2.0.0-11.el7ost
elif [[ "${RELEASE}" -eq "10" ]]; then
    exitoutdated
    # openstack-tripleo-common needs to be 5.4.1-6 or later
    is_required_rpm_over openstack-tripleo-common openstack-tripleo-common-5.4.1-6.el7ost
else
    echo "only applies to OSP8, OSP9 and OSP10" >&2
    exit ${RC_SKIPPED}
fi

exit ${RC_OKAY}
