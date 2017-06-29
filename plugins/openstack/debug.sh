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


function debug_check_live(){

  continue

}

function debug_check_sosreport(){

  echo ""
  echo "Running Debug module"
  echo "------------------------"
  LIST_OF_PROJECTS="ceilometer glance heat keystone neutron nova swift httpd"
  for PROJECT in $LIST_OF_PROJECTS; do
      for LOGFILE in ${DIRECTORY}/etc/${PROJECT}/*.conf; do
	[ -e "$LOGFILE" ] || continue
	  grep_file "${LOGFILE}" "^debug.*=.*true"
      done
  done

}

# Checks if the debug is enabled
debug_check_${CHECK_MODE}
