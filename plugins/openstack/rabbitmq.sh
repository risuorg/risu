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
REFNAME="RabbitMQ module"

# Add all needed functions
function count_lines(){

  if [ -e "$1" ]
  then
    WC=$(grep "${2}" ${1} | wc -l)
    if [[ ${WC} -eq 0 ]]
    then
      good "${2} is in ${1} (${WC} times)"
    elif [[ ${WC} -gt 0 ]] && [[ ${WC} -lt 50 ]]
    then
      warn "${2} is in ${1} (${WC} times)"
      if [ -n "$3" ]
      then
        echo "${3}"
        echo ""
      fi
    else
      bad "${2} is in ${1} (${WC} times)"
      if [ -n "$3" ]
      then
        echo "${3}"
        echo ""
      fi
    fi
  else
    warn "RabbitMQ module: Missing file ${1}"
  fi

}

function rabbitmq_check_live(){

  continue

}

function rabbitmq_check_sosreport(){

if [ ${DISCOVERED_NODE} == "director" ]
then
  FILE_DESCRIPTORS=$(awk -v target="${TARGET_HOSTNAME}" '$4 ~ target { flag = 1 } \
  flag = 1 && /file_descriptors/ { getline; print ; exit }' \
  "${DIRECTORY}/sos_commands/rabbitmq/rabbitmqctl_report" | egrep -o '[0-9]+')
elif [ ${DISCOVERED_NODE} == "controller" ]
then
  FILE_DESCRIPTORS=$(awk -v target="${TARGET_HOSTNAME}" '$4 ~ target { flag = 1 } \
  flag = 1 && /file_descriptors/ { print ; exit }' \
  "${DIRECTORY}/sos_commands/rabbitmq/rabbitmqctl_report" | egrep -o '[0-9]+')
else
  continue
fi

if [ "${FILE_DESCRIPTORS}" -ge  "65336" ]
then
  good "There are currently ${FILE_DESCRIPTORS} file_descriptors available."
else
  bad "There are ${FILE_DESCRIPTORS} file_descriptors available."
fi

LIST_OF_PROJECTS="ceilometer glance heat keystone neutron nova swift"
for PROJECT in $LIST_OF_PROJECTS; do
    for LOGFILE in ${DIRECTORY}/var/log/${PROJECT}/*.log; do
      [ -e "$LOGFILE" ] || continue
	count_lines "$LOGFILE" "AMQP server on .* is unreachable"
    done
done

}

# Rabbits everywhere
rabbitmq_check_${CHECK_MODE}


unset count_lines

