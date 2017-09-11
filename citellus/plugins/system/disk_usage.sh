#!/bin/bash

# Copyright (C) 2017   Robin Cernin (rcernin@redhat.com)

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

# error if disk usage is greater than $CITELLUS_DISK_MAX_PERCENT

: ${CITELLUS_DISK_MAX_PERCENT=75}

if [[ $CITELLUS_LIVE = 0 ]];  then
  if [[ ! -f ${CITELLUS_ROOT}/df ]]; then
    echo "file /df not found." >&2
    exit $RC_SKIPPED
  fi
  DISK_USE_CMD="cat ${CITELLUS_ROOT}/df"
else
  DISK_USE_CMD="df -P"
fi

result=$($DISK_USE_CMD |
	awk -vdisk_max_percent=$CITELLUS_DISK_MAX_PERCENT \
	'/^\/dev/ && substr($5, 0, length($5)-1) > disk_max_percent {
		print $6,$5
	}')

if [ -n "$result" ]; then
  echo "${result}" >&2
  exit $RC_FAILED
fi
