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

# this can run against live

if [ ! "x$CITELLUS_LIVE" = "x1" ]; then
    echo "works on live-system only" >&2
    exit $RC_SKIPPED
fi

# This test requires mysql
which mysql > /dev/null 2>&1
RC=$?

if [ "x$RC" = "x0" ]; then
    # Collect information from THREADS_CONNECTED
    mysql -u root -e 'SELECT * FROM INFORMATION_SCHEMA.GLOBAL_STATUS where VARIABLE_NAME="THREADS_CONNECTED";'
    RC=$?
    if [ "x$RC" = "x0" ]; then
        THREADS_CONNECTED=$(mysql -u root -e 'SELECT * FROM INFORMATION_SCHEMA.GLOBAL_STATUS where VARIABLE_NAME="THREADS_CONNECTED";' | egrep -o '[0-9]+')
    else
        echo "no connection to the database" >&2
        exit $RC_SKIPPED
    fi
    # Check for HAproxy topic in haproxy.cfg and pick the maxconn value
    HAPROXY_MYSQL=$(awk '/listen mysql/,/^$/' /etc/haproxy/haproxy.cfg | grep maxconn | egrep -o '[0-9]+')
    HAPROXY_DEFAULTS=$(awk '/defaults/,/^$/' /etc/haproxy/haproxy.cfg | grep maxconn | egrep -o '[0-9]+')

    # If the HAproxy mysql is empty assign the value from defaults
    if [[ -z ${HAPROXY_MYSQL} ]]; then
        HAPROXY_MYSQL=${HAPROXY_DEFAULTS}
    fi
else
    echo "missing mysql binaries" >&2
    exit $RC_SKIPPED
fi
# Now that we have all needed compare the value from HAproxy and database.
if [[ ! -z ${THREADS_CONNECTED} ]]; then
    if [[ "${THREADS_CONNECTED}" -ge ${HAPROXY_MYSQL} ]]; then
        exit $RC_FAILED
    elif [[ "${THREADS_CONNECTED}" -lt ${HAPROXY_MYSQL} ]]; then
        exit $RC_OKAY
    fi
fi
