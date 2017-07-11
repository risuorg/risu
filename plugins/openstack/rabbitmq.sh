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

if [ ${DISCOVERED_NODE} == "compute" ]
then
  continue
else
  FILE_DESCRIPTORS=$(rabbitmqctl report | awk -v target="${TARGET_HOSTNAME}" '$4 ~ target { flag = 1 } \
  flag = 1 && /total_limit/ { print }' | egrep -o '[0-9]+')
  USED_FILE_DESCRIPTORS=$(rabbitmqctl report | awk -v target="${TARGET_HOSTNAME}" '$4 ~ target { flag = 1 } \
  flag = 1 && /total_used/ { print }' | egrep -o '[0-9]+')
fi

if [ "${FILE_DESCRIPTORS}" -ge  "65336" ]
then
  good "There are currently ${FILE_DESCRIPTORS} total_limit file_descriptors."
else
  bad "There are ${FILE_DESCRIPTORS} total_limit file_descriptors."
fi

AVAILABLE_FILE_DESCRIPTORS=$(( FILE_DESCRIPTORS - USED_FILE_DESCRIPTORS ))
if [ "${AVAILABLE_FILE_DESCRIPTORS}" -gt "1000" ]
then
  good "There are ${USED_FILE_DESCRIPTORS} total_used file_descriptors, ${FILE_DESCRIPTORS} total_limit and ${AVAILABLE_FILE_DESCRIPTORS} still unused."
else
  bad "There are ${USED_FILE_DESCRIPTORS} total_used file_descriptors, ${FILE_DESCRIPTORS} total_limit and ${AVAILABLE_FILE_DESCRIPTORS} still unused."
fi

LIST_OF_PROJECTS="ceilometer glance heat keystone neutron nova swift"
for PROJECT in $LIST_OF_PROJECTS; do
    for LOGFILE in /var/log/${PROJECT}/*.log; do
      [ -e "$LOGFILE" ] || continue
	count_lines "$LOGFILE" "AMQP server on .* is unreachable"
    done
done

}

function rabbitmq_check_sosreport(){

if [ ${DISCOVERED_NODE} == "compute" ]
then
  continue
else
  FILE_DESCRIPTORS=$(awk -v target="${TARGET_HOSTNAME}" '$4 ~ target { flag = 1 } \
  flag = 1 && /total_limit/ { print ; exit }' \
  "${DIRECTORY}/sos_commands/rabbitmq/rabbitmqctl_report" | egrep -o '[0-9]+')
  USED_FILE_DESCRIPTORS=$(awk -v target="${TARGET_HOSTNAME}" '$4 ~ target { flag = 1 } \
  flag = 1 && /total_used/ { print ; exit }' \
  "${DIRECTORY}/sos_commands/rabbitmq/rabbitmqctl_report" | egrep -o '[0-9]+')
fi

if [ "${FILE_DESCRIPTORS}" -ge  "65336" ]
then
  good "There are currently ${FILE_DESCRIPTORS} total_limit file_descriptors."
else
  bad "There are ${FILE_DESCRIPTORS} total_limit file_descriptors."
fi

AVAILABLE_FILE_DESCRIPTORS=$(( FILE_DESCRIPTORS - USED_FILE_DESCRIPTORS ))
if [ "${AVAILABLE_FILE_DESCRIPTORS}" -gt "1000" ]
then
  good "There are ${USED_FILE_DESCRIPTORS} total_used file_descriptors, ${FILE_DESCRIPTORS} total_limit and ${AVAILABLE_FILE_DESCRIPTORS} still unused."
else
  bad "There are ${USED_FILE_DESCRIPTORS} total_used file_descriptors, ${FILE_DESCRIPTORS} total_limit and ${AVAILABLE_FILE_DESCRIPTORS} still unused."
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

