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

# Reference: https://bugzilla.redhat.com/show_bug.cgi?id=1473713

ERROR=0

if [ ! -f "${CITELLUS_ROOT}/var/spool/cron/keystone" ]; then
  echo "file /var/spool/cron/keystone not found." >&2
  ERROR=2
fi
if ! awk '/keystone-manage token_flush/ && /^[^#]/ { print $0 }' "${CITELLUS_ROOT}/var/spool/cron/keystone"; then
  echo "crontab keystone cleanup is not set" >&2
  ERROR=1
elif awk '/keystone-manage token_flush/ && /^[^#]/ { print $0 }' "${CITELLUS_ROOT}/var/spool/cron/keystone"; then
  COUNT=$(awk '/keystone-manage token_flush/ && /^[^#]/ { print $0 }' "${CITELLUS_ROOT}/var/spool/cron/keystone" 2>&1|egrep  '^1 0'  -c)
  if [ "x$COUNT" = "x1" ];
  then
    	echo "Token flush not running every hour: https://bugzilla.redhat.com/show_bug.cgi?id=1473713" >&2
      ERROR=1
  fi
fi
if [ ! -f "${CITELLUS_ROOT}/var/log/keystone/keystone.log" ]; then
  echo "file /var/log/keystone/keystone.log not found." >&2
  ERROR=2
fi

COUNT=$(egrep -c 'ERROR keystone DBDeadlock: .*pymysql.err.Internal.* try restarting transaction.*DELETE FROM token WHERE token.expires.*' "${CITELLUS_ROOT}/var/log/keystone/keystone.log")
if [ "x$COUNT" != "x0" ];
then
    echo "Errors on token expiration, check: https://bugzilla.redhat.com/show_bug.cgi?id=1473713" >&2
    ERROR=1
fi

exit $ERROR
