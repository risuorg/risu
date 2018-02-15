#!/bin/bash

# Copyright (C) 2017 Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)

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

# long_name: Concurrent use of iptables
# description: Checks for iptables xlock errors
# bugzilla: https://bugzilla.redhat.com/show_bug.cgi?id=1489066
# priority: 800

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

is_required_file "${CITELLUS_ROOT}/var/log/neutron/dhcp-agent.log"

is_lineinfile 'Another app is currently holding the xtables lock' "${CITELLUS_ROOT}/var/log/neutron/dhcp-agent.log" && echo $"errors on iptables xlock, check: https://bugzilla.redhat.com/show_bug.cgi?id=1489066" >&2 && exit ${RC_FAILED}

exit ${RC_OKAY}
