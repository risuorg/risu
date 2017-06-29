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


# Add all needed functions
function count_lines(){

  if [ -e "$1" ]
  then
    WC=$(grep "${2}" ${1} | wc -l)
    if [[ ${WC} -eq 0 ]]
    then
      good "Traceback module: ${1} (${WC} times)"
    elif [[ ${WC} -gt 0 ]] && [[ ${WC} -lt 50 ]]
    then
      warn "Traceback module: ${1} (${WC} times)"
      if [ -n "$3" ]
      then
        echo "${3}"
        echo ""
      fi
    else
      bad "Traceback module: ${1} (${WC} times)"
      if [ -n "$3" ]
      then
        echo "${3}"
        echo ""
      fi
    fi
  else
    warn "Traceback module: Missing file ${1}"
  fi

}

function traceback_check_live(){

  echo ""
  echo "Running Traceback module"
  echo "------------------------"

  LIST_OF_PROJECTS="ceilometer glance heat keystone neutron nova swift httpd"
  for PROJECT in $LIST_OF_PROJECTS; do
      for LOGFILE in /var/log/${PROJECT}/*.log; do
	[ -e "$LOGFILE" ] || continue
	  count_lines "$LOGFILE" "Traceback"
      done
  done

}

function traceback_check_sosreport(){

  echo ""
  echo "Running Traceback module"
  echo "------------------------"
  LIST_OF_PROJECTS="ceilometer glance heat keystone neutron nova swift httpd"
  for PROJECT in $LIST_OF_PROJECTS; do
      for LOGFILE in ${DIRECTORY}/var/log/${PROJECT}/*.log; do
	[ -e "$LOGFILE" ] || continue
	  count_lines "$LOGFILE" "Traceback"
      done
  done

}

# Tracebacks everywhere
traceback_check_${CHECK_MODE}


unset count_lines
