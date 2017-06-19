#!/bin/bash

# Copyright (C) 2017   Robin Cernin (rcernin@redhat.com)

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

# Checking ERRORS
# Ref: None
REFNAME="My Custom Module"
REFOSP_VERSION="liberty mitaka newton ocata"
REFNODE_TYPE="controller"


# https://bugs.launchpad.net/keystone/+bug/1649616/
count_lines "${DIRECTORY}/var/log/keystone/keystone.log" "Got error 5 during COMMIT" \
" \_ This is known bug in keystone-manage token_flush - Ref: https://bugs.launchpad.net/keystone/+bug/1649616/"

# Check OpenStack services in undercloud are running and aren't failed

grep_file_rev "${DIRECTORY}/sos_commands/systemd/systemctl_list-units_--all" "neutron.*failed|openstack.*failed"
