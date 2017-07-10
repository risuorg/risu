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
REFNAME="Debug module"

LIST_OF_PROJECTS="ceilometer glance heat keystone neutron nova swift httpd"
LIST_OF_CONFIGS="ceilometer.conf glance-api.conf heat.conf keystone.conf neutron.conf nova.conf swift.conf"

function debug_check_live(){

  for PROJECT in $LIST_OF_PROJECTS; do
    for CONFIG in $LIST_OF_CONFIGS; do 
      for LOGFILE in /etc/${PROJECT}/${CONFIG}; do
	[ -e "$LOGFILE" ] || continue
	  grep_file "${LOGFILE}" "^debug.*=.*true"
      done
    done
  done

}

function debug_check_sosreport(){

  for PROJECT in $LIST_OF_PROJECTS; do
    for CONFIG in $LIST_OF_CONFIGS; do 
      for LOGFILE in ${DIRECTORY}/etc/${PROJECT}/${CONFIG}; do
	[ -e "$LOGFILE" ] || continue
	  grep_file "${LOGFILE}" "^debug.*=.*true"
      done
    done
  done

}

# Checks if the debug is enabled
debug_check_${CHECK_MODE}
