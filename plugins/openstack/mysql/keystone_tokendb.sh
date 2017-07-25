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

# this can run against live

if [ ! "x$CITELLUS_LIVE" = "x1" ]; then 
  echo "works on live-system only" >&2
  exit 2
fi

TOKENS=$(mysql keystone -e 'select count(*) from token where token.expires < CURTIME();' | egrep -o '[0-9]+')
[ -z ${TOKENS} ] && exit 3

if [[ "${TOKENS}" -ge 1000 ]]; then
    exit 1
elif [[ "${TOKENS}" -lt 1000 ]]; then
    exit 0
fi
