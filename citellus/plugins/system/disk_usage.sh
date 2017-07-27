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

# disk usage is greater than 75%

if [ "x$CITELLUS_LIVE" = "x0" ];  then
  if [ ! -f "${CITELLUS_ROOT}/df" ]; then
    echo "file /df not found." >&2
    exit 2
  fi
  DISK_USE=$(cat "${CITELLUS_ROOT}"/df | awk '/dev.*\/$/{print $5}')
  if [[ ${DISK_USE%%%*} -ge "75" ]]
  then
    echo "${DISK_USE}" >&2
    exit 1
  fi
elif [ "x$CITELLUS_LIVE" = "x1" ]; then
  DISK_USE=$(read -d '' -ra df_arr < <(LC_ALL=C df -P /); echo "${df_arr[11]}")
  if [[ ${DISK_USE%%%*} -ge "75" ]]
  then
    echo "${DISK_USE}" >&2
    exit 1
  fi
fi
