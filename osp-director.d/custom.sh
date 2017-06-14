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


# Check for iptables -t nat -j REDIRECT rule for metadata server exists.
# Happens that when deployment is stuck without any FAILURE might be
# caused by this.

grep_file "${DIRECTORY}/sos_commands/networking/iptables_-t_nat_-nvL" "REDIRECT.*169.254.169.254"

# Check OpenStack services in undercloud are running and aren't failed

grep_file_rev "${DIRECTORY}/sos_commands/systemd/systemctl_list-units_--all" "neutron.*failed|openstack.*failed"
