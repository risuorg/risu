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

# long_name: Keystone token flush job failure
# description: Checks for transaction size exceeded on keystone token purge
# bugzilla: https://bugs.launchpad.net/keystone/+bug/1649616
# priority: 600

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

is_required_file "${CITELLUS_ROOT}/var/log/keystone/keystone.log"

is_lineinfile "Got error 5 during COMMIT" "${CITELLUS_ROOT}/var/log/keystone/keystone.log" && echo $"https://bugs.launchpad.net/keystone/+bug/1649616/" >&2 && exit ${RC_FAILED}
exit ${RC_OKAY}
