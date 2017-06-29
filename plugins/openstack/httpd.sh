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

# Checking httpd
# Ref: None

# Add all needed functions
function count_lines(){

  if [ -e "$1" ]
  then
    WC=$(grep "${2}" ${1} | wc -l)
    if [[ ${WC} -eq 0 ]]
    then
      good "httpd module: Looking for ${2} in ${1} (${WC} times)"
    elif [[ ${WC} -gt 0 ]] && [[ ${WC} -lt 50 ]]
    then
      warn "httpd module: Looking for ${2} in ${1} (${WC} times)"
      if [ -n "$3" ]
      then
        echo "${3}"
        echo ""
      fi
    else
      bad "httpd module: Looking for ${2} in ${1} (${WC} times)"
      if [ -n "$3" ]
      then
        echo "${3}"
        echo ""
      fi
    fi
  else
    warn "httpd module: Missing file ${1}"
  fi

}

function httpd_check_live(){

  continue

}

function httpd_check_sosreport(){

  echo ""
  echo "Running httpd module"
  echo "--------------------"

  count_lines "${DIRECTORY}/var/log/httpd/error_log" "MaxRequestWorkers" \
  " \_ Check /etc/httpd/prefork.conf values MaxClients and ServerLimit are set to value 512 - Ref: https://bugzilla.redhat.com/show_bug.cgi?id=1163516"

  for LOGFILE in ${DIRECTORY}/var/log/httpd/*.log; do
    [ -e "$LOGFILE" ] || continue
    count_lines "${LOGFILE}" "Permission denied" \
  "+-------------------+
  | Possible Solution |
  +-------------------+
  Please check your permissions/ownership on keystone.log hasn't changed. 

  [root@controller-1 ~]# ls -lad /var/log/keystone/
  drwxr-x---. 2 keystone keystone 4096 Jun 15 03:48 /var/log/keystone/
  [root@controller-1 ~]# ls -la /var/log/keystone/keystone.log
  -rw-rw----. 1 root keystone 33376394 Jun 15 09:46 /var/log/keystone/keystone.log"
  done


  # Check httpd service is running and isn't failed

  grep_file_rev "${DIRECTORY}/sos_commands/systemd/systemctl_list-units_--all" "httpd.*failed"

}

# Hardware requirements
httpd_check_${CHECK_MODE}

unset count_lines
# vim: ts=2 sw=2 et

