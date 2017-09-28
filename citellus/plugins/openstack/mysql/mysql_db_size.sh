#!/bin/bash
# Copyright (C) 2017   Pablo Caruana (pcaruana@redhat.com | pablo.caruana@gmail.com)
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

# this can run against live

if [ ! "x$CITELLUS_LIVE" = "x1" ]; then
  echo "works on live-system only" >&2
  exit $RC_SKIPPED
fi

# This test requires mysql

MYSQL_DIR="/var/lib/mysql"
which mysql > /dev/null 2>&1
RC=$?

if [ "x$RC" = "x0" ];
then
    # databases  larger than 10 rounded size in GB unit
    mysql -t -u root -e 'SELECT table_schema "database",round((data_length+index_length)/(1024 * 1024 * 1024),2) table_size \
                                 FROM  information_schema.TABLES WHERE (DATA_LENGTH+INDEX_LENGTH)/ ( 1024 * 1024 * 1024 ) > 10;'
    RC=$?
    if [ "x$RC" = "x0" ];
    then
        # Databases tables larger than 10 GB
        mysql -t -u root -e 'SELECT table_schema AS DB_NAME, TABLE_NAME, ROUND(( data_length + index_length ) / ( 1024 * 1024 * 1024 ), 2) AS TABLE_SIZE_in_GB \
                                              FROM information_schema.TABLES WHERE (DATA_LENGTH+INDEX_LENGTH)/ ( 1024 * 1024 * 1024 ) > 10;'
    else
        echo "no connection to the database" >&2
        exit $RC_SKIPPED
    fi
else
    echo "missing mysql binaries" >&2
    exit $RC_SKIPPED
fi

if [ -d "${MYSQL_DIR}" ];
then
    #Db disk usage for galera cache, ibdata and ib_log kinds - gb unit size kinds could be associate with perfomance degradation and a potential need of table truncate operations
    du -h --threshold=1G ${MYSQL_DIR}/* | sort -nr  | egrep -i "galera.cache|ibdata|ib_log"
    exit $RC_OKAY
else
    echo "$MYSQL_DIR doesn't exists" >&2
    exit $RC_FAILED
fi
