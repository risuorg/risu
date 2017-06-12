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

# RabbitMQ Module
# Ref: 

echo "+--------------------------------------------+"
echo "|              Checking RabbitMQ             |"
echo "+--------------------------------------------+"

# RabbitMQ

FILE_DESCRIPTORS=$(awk -v target="${TARGET_HOSTNAME}" '$4 ~ target { flag = 1 } \
flag = 1 && /file_descriptors/ { print ; exit }' \
"${DIRECTORY}/sos_commands/rabbitmq/rabbitmqctl_report" | egrep -o '[0-9]+')

if [ "${FILE_DESCRIPTORS}" -ge  "65336" ]
then
  good "There are currently ${FILE_DESCRIPTORS} file_descriptors available."
else
  bad "There are ${FILE_DESCRIPTORS} file_descriptors available."
fi

LIST_OF_PROJECTS="ceilometer glance heat keystone neutron nova swift"
for PROJECT in $LIST_OF_PROJECTS; do
    for FILE in ${DIRECTORY}/var/log/${PROJECT}/*.log; do
      [ -e "$FILE" ] || continue
        count_lines "$FILE" "AMQP server on .* is unreachable"
    done
done
