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

# long_name: Number of expired tokens in database
# description: Checks for expired tokens in keystone database
# priority: 900

# this can run against live

if [[ ! "x$CITELLUS_LIVE" = "x1" ]]; then
    echo "works on live-system only" >&2
    exit ${RC_SKIPPED}
fi

# This test requires mysql
which mysql > /dev/null 2>&1
RC=$?

if [[ "x$RC" = "x0" ]]; then
    # Test connection to the db
    _test=$(mysql keystone -e "DESC token" 2>&1)
    RC=$?
    if [[ "x$RC" = "x0" ]]; then
        TOKENS=$(mysql keystone -sN -e "select table_rows from information_schema.tables where table_name = 'token'")
    else
        echo -e "ERROR connecting to the database\n${_test}" >&2
        exit ${RC_SKIPPED}
    fi
else
    echo "missing mysql binaries" >&2
    exit ${RC_SKIPPED}
fi

if [[ ! -z ${TOKENS} ]] ; then
    if [[ "${TOKENS}" -ge 1000 ]]; then
        exit ${RC_FAILED}
    elif [[ "${TOKENS}" -lt 1000 ]]; then
        exit ${RC_OKAY}
    fi
fi
