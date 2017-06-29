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

# Checking anything interesting
# Ref: None

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
    warn "Anything else module: Missing file ${1}"
  fi

}

function anything_check_live(){

  continue

}

function anything_check_sosreport(){

  echo ""
  echo "Running Anything else module"
  echo "----------------------------"
  # https://bugs.launchpad.net/keystone/+bug/1649616/
  count_lines "${DIRECTORY}/var/log/keystone/keystone.log" "Got error 5 during COMMIT" \
  " \_ This is known bug in keystone-manage token_flush - Ref: https://bugs.launchpad.net/keystone/+bug/1649616/"

  # Check OpenStack services in undercloud are running and aren't failed
  grep_file_rev "${DIRECTORY}/sos_commands/systemd/systemctl_list-units_--all" "neutron.*failed|openstack.*failed"

  # Check for iptables -t nat -j REDIRECT rule for metadata server exists.
  # Happens that when deployment is stuck without any FAILURE might be
  # caused by this.
  grep_file "${DIRECTORY}/sos_commands/networking/iptables_-t_nat_-nvL" "REDIRECT.*169.254.169.254"

  # Check OpenStack services in undercloud are running and aren't failed
  grep_file_rev "${DIRECTORY}/sos_commands/systemd/systemctl_list-units_--all" "neutron.*failed|openstack.*failed"

}

anything_check_${CHECK_MODE}


unset count_lines

