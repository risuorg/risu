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

# we can run this against fs snapshot or live system

if [ "x$CITELLUS_LIVE" = "x1" ];  then

  if ps -elf | grep [n]ova-compute; then
    echo "works only against controller node" >&2
    exit 2
  else
    FILE_DESCRIPTORS=$(rabbitmqctl report | awk -v target="$(hostname)" '$4 ~ target { flag = 1 } \
    flag = 1 && /total_limit/ { print }' | egrep -o '[0-9]+')
    USED_FILE_DESCRIPTORS=$(rabbitmqctl report | awk -v target="$(hostname)" '$4 ~ target { flag = 1 } \
    flag = 1 && /total_used/ { print }' | egrep -o '[0-9]+')
  fi

  if [ "${FILE_DESCRIPTORS}" -lt  "65336" ]; then 
    echo "total ${FILE_DESCRIPTORS}" >&2
    flag=1
  fi

  AVAILABLE_FILE_DESCRIPTORS=$(( FILE_DESCRIPTORS - USED_FILE_DESCRIPTORS ))
  if [ "${AVAILABLE_FILE_DESCRIPTORS}" -lt "16000" ]; then
    echo "total_used ${USED_FILE_DESCRIPTORS}" >&2
    echo "available ${AVAILABLE_FILE_DESCRIPTORS}" >&2
    flag=1
  fi

elif [ "x$CITELLUS_LIVE" = "x0" ]; then

  if grep [n]ova-compute "${CITELLUS_ROOT}/ps"; then
    echo "works only against controller node" >&2
    exit 2
  else
    if [ -e "${CITELLUS_ROOT}/sos_commands/rabbitmq/rabbitmqctl_report" ]; then
      FILE_DESCRIPTORS=$(awk -v target="$(cat ${CITELLUS_ROOT}/hostname)" '$4 ~ target { flag = 1 } \
      flag = 1 && /total_limit/ { print ; exit }' \
      "${CITELLUS_ROOT}/sos_commands/rabbitmq/rabbitmqctl_report" | egrep -o '[0-9]+')
      USED_FILE_DESCRIPTORS=$(awk -v target="$(cat ${CITELLUS_ROOT}/hostname)" '$4 ~ target { flag = 1 } \
      flag = 1 && /total_used/ { print ; exit }' \
      "${CITELLUS_ROOT}/sos_commands/rabbitmq/rabbitmqctl_report" | egrep -o '[0-9]+')
    else
      echo "file /sos_commands/rabbitmq/rabbitmqctl_report not found" >&2
      exit 2
    fi
  fi

  if [ "${FILE_DESCRIPTORS}" -lt  "65336" ]; then
    echo "total ${FILE_DESCRIPTORS}" >&2
    flag=1
  fi

  AVAILABLE_FILE_DESCRIPTORS=$(( FILE_DESCRIPTORS - USED_FILE_DESCRIPTORS ))
  if [ "${AVAILABLE_FILE_DESCRIPTORS}" -lt "16000" ]; then
    echo "total_used ${USED_FILE_DESCRIPTORS}" >&2
    echo "available ${AVAILABLE_FILE_DESCRIPTORS}" >&2
    flag=1
  fi

fi

[[ "x$flag" = "x" ]] || exit 1
