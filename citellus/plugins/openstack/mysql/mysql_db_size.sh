#!/bin/bash
# Copyright (C) 2017   Pablo Caruana (pcaruana@redhat.com)
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
# This test requires mysql

MYSQL_DIR="/var/lib/mysql"
which mysql > /dev/null 2>&1
RC=$?

if [ "x$RC" = "x0" ];
then
    echo "DB SCHEMA SIZE" >&2
    MYSQL_DB_SIZE=$(mysql -u root -e 'SELECT table_schema "DB Name", Round(Sum(data_length + index_length) / 1024 / 1024, 1) "DB Size in MB" FROM information_schema.tables GROUP BY table_schema;')
    RC=$?
    if [ "x$RC" = "x0" ];
    then echo $MYSQL_DB_SIZE >&2
      else
        echo "no connection to the database" >&2
        exit $RC_SKIPPED
    fi
else
    echo "missing mysql binaries" >&2
    exit $RC_SKIPPED
fi

if [ "$(ls -A $MYSQL_DIR)" ];
 then MYSQL_DISK_USAGE=$(du -mshc $MYSQL_DIR/*)
      echo "DB DISK USAGE details" >&2
      echo $MYSQL_DISK_USAGE >&2
      exit $RC_OKAY
     else
    echo "$MYSQL_DIR doesn't exists" >&2
    exit $RC_FAILED
fi
