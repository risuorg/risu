#!/bin/bash

# Copyright (C) 2018    Robin Černín (rcernin@redhat.com)

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

# long_name: Swift cluster might break when replacing or adding new nodes
# description: Director might break Swift cluster when replacing or adding new nodes.
# bugzilla: https://bugzilla.redhat.com/show_bug.cgi?id=1310865
# priority: 800

# Load common functions
[ -f "${CITELLUS_BASE}/common-functions.sh" ] && . "${CITELLUS_BASE}/common-functions.sh"

exitoutdated(){
    echo $"outdated openstack-tripleo-heat-templates might break Swift cluster when replacing or adding new nodes" >&2
}

if [[ -z $(is_rpm tripleo-heat-templates) && -z $(is_rpm python-tripleoclient) ]]; then
    echo "works on director node only" >&2
    exit $RC_SKIPPED
fi

RELEASE=$(discover_osp_version)
if [[ "${RELEASE}" -eq "7" ]]; then
    exitoutdated
    # openstack-tripleo-heat-templates needs to be 0.8.6-124 or later
    is_required_rpm_over openstack-tripleo-heat-templates openstack-tripleo-heat-templates-0.8.6-124.el7ost
elif [[ "${RELEASE}" -eq "8" ]]; then
    exitoutdated
    # openstack-tripleo-heat-templates needs to be 0.8.14-1 or later
    is_required_rpm_over openstack-tripleo-heat-templates openstack-tripleo-heat-templates-0.8.14-1.el7ost
elif [[ "${RELEASE}" -eq "9" ]]; then
    exitoutdated
    # openstack-tripleo-common needs to be 2.0.0-11 or later
    is_required_rpm_over openstack-tripleo-common openstack-tripleo-common-2.0.0-11.el7ost
elif [[ "${RELEASE}" -eq "10" ]]; then
    exitoutdated
    # openstack-tripleo-heat-templates needs to be 5.4.1-6 or later
    is_required_rpm_over openstack-tripleo-heat-templates openstack-tripleo-heat-templates
elif [[ "${RELEASE}" -eq "11" ]]; then
    exitoutdated
    # openstack-tripleo-heat-templates needs to be 6.0.0-0 or later
    is_required_rpm_over openstack-tripleo-heat-templates openstack-tripleo-heat-templates-6.0.0-0.el7ost
else
    echo "only applies to OSP7, OSP8, OSP9, OSP10 and OSP11" >&2
    exit $RC_SKIPPED
fi

exit $RC_OKAY
