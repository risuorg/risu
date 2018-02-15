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

# long_name: HAProxy maximum connections
# description: Checks HAProxy max connections
# priority: 500

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
    _test=$(mysql -u root -e exit 2>&1)
    RC=$?
    # Collect information from THREADS_CONNECTED
    if [[ "x$RC" = "x0" ]]; then
        THREADS_CONNECTED=$(mysql -sN -u root -e 'SELECT VARIABLE_VALUE FROM INFORMATION_SCHEMA.GLOBAL_STATUS where VARIABLE_NAME="THREADS_CONNECTED";')
    else
        echo -e "ERROR connecting to the database\n${_test}" >&2
        exit ${RC_SKIPPED}
    fi
    # Check for HAproxy topic in haproxy.cfg and pick the maxconn value
    HAPROXY_MYSQL=$(awk '/defaults|listen mysql/,/^$/ {if ($1 == "maxconn" && $2 ~ /[0-9]+/) max=$2}; END {print max}' /etc/haproxy/haproxy.cfg)

    # If the HAPROXY_MYSQL is empty, set as the DEFAULT_MAXCONN at build time
    if [[ -z ${HAPROXY_MYSQL} ]]; then
        HAPROXY_MYSQL=$(haproxy -vv 2>&1 | sed 's/.*maxconn = \([0-9]\+\).*/\1/;tx;d;:x')
    fi
else
    echo "missing mysql binaries" >&2
    exit ${RC_SKIPPED}
fi

# Now that we have all needed compare the value from HAproxy and database.
if [[ ! -z ${THREADS_CONNECTED} ]]; then
    if [[ "${THREADS_CONNECTED}" -ge ${HAPROXY_MYSQL} ]]; then
        exit ${RC_FAILED}
    elif [[ "${THREADS_CONNECTED}" -lt ${HAPROXY_MYSQL} ]]; then
        exit ${RC_OKAY}
    fi
fi
