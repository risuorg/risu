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

# long_name: Checks that keystone uses supported backends
# description: Only two backends are supported sql and ldap
# priority: 200

# this can run against live and also fs snapshot

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

config_file="${CITELLUS_ROOT}/etc/keystone/keystone.conf"

is_required_file ${config_file}

backends=$(iniparser "$config_file" identity driver)

supported=1
for backend in ${backends};do
    case ${backend} in
        "keystone.identity.backends.sql.Identity")
            # do nothing
            ;;
        "keystone.identity.backends.ldap.Identity")
            # do nothing
            ;;
        "ldap")
            # do nothing
            ;;
        "sql")
            # do nothing
            ;;
        "")
            # do nothing
            ;;
        *)
            echo -n $"Unsupported keystone identity backend found " >&2
            echo ${backend} >&2
            supported=0
            ;;
    esac
done

if [[ "$supported" -ne "1" ]]; then
    exit ${RC_FAILED}
fi

exit ${RC_OKAY}
