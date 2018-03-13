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

# we can run this against fs snapshot or live system

# long_name: InnoDB file per table
# description: Checks if mysql is configured to use one file per table for innodb
# priority: 300

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

if ! is_process mysqld; then
    echo "only runs on controllers" >&2
    exit ${RC_SKIPPED}
fi

is_required_file "${CITELLUS_ROOT}/etc/my.cnf.d/galera.cnf" "${CITELLUS_ROOT}/etc/my.cnf"

if [[ "$(iniparser "${CITELLUS_ROOT}/etc/my.cnf.d/galera.cnf" mysqld innodb_file_per_table)" == "on" ]]; then
    exit ${RC_OKAY}
elif [[ "$(iniparser "${CITELLUS_ROOT}/etc/my.cnf" mysqld innodb_file_per_table)" == "on" ]]; then
    exit ${RC_OKAY}
else
    echo $"innodb_file_per_table not set in /etc/my.cnf.d/galera.cnf or /etc/my.cnf" >&2
    echo $"Check: https://bugzilla.redhat.com/show_bug.cgi?id=1277598" >&2
    exit ${RC_FAILED}
fi
