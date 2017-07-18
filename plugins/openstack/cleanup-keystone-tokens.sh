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

# Cleanup keystone tokens
# Ref: None
REFNAME="Cleanup keystone tokens"

# Add all needed functions
function count_lines(){

  if [ -e "$1" ]
  then
    WC=$(grep "${2}" ${1} | wc -l)
    if [[ ${WC} -eq 0 ]]
    then
      bad "Cleanup keystone token has run ${WC} times."
    else
      good "Cleanup keystone token has run ${WC} times."
    fi
  else
    warn "Missing file ${1}"
  fi

}

function keystone_check_live(){

  # Crontab check
  grep_file "/var/spool/cron/keystone" "keystone-manage token_flush"
  awk '/keystone-manage/ && /^[^#]/ { print $0 }' "/var/spool/cron/keystone" 2>/dev/null

  # Mysql check
  TOKENS=$(mysql keystone -e 'select count(*) from token where token.expires < CURTIME();' | egrep -o '[0-9]+')
  if [[ ${TOKENS} -ge 1000 ]]
  then
    bad "There are ${TOKENS} expired tokens in MySQL. Possible that expired tokens don't get deleted."
  else
    good "There are currently ${TOKENS} expired tokens in MySQL." 
  fi

  if [ ! -d "${DIRECTORY}/var/log/keystone" ]
  then
    continue
  fi

  # Keystone cleanup last-run
  LASTRUN=$(awk '/Total expired tokens removed/ { print $1 " " $2 }' /var/log/keystone/keystone.log | tail -1)
  if [ -n "${LASTRUN}" ]
  then
    good "Cleanup keystone last-run performed at ${LASTRUN}."
  else
    bad "Cleanup keystone haven't finished once."
  fi

  count_lines "/var/log/keystone/keystone.log" "Total expired tokens removed"
}

function keystone_check_sosreport(){

  # Crontab check
  grep_file "${DIRECTORY}/var/spool/cron/keystone" "keystone-manage token_flush"
  awk '/keystone-manage/ && /^[^#]/ { print $0 }' "${DIRECTORY}/var/spool/cron/keystone" 2>/dev/null

  if [ ! -d "${DIRECTORY}/var/log/keystone" ]
  then
    continue
  fi
  # Keystone cleanup last-run
  LASTRUN=$(awk '/Total expired tokens removed/ { print $1 " " $2 }' "${DIRECTORY}/var/log/keystone/keystone.log" | tail -1)
  if [ -n "${LASTRUN}" ]
  then
    good "Cleanup keystone last-run performed at ${LASTRUN}."
  else
    bad "Cleanup keystone haven't finished once."
  fi

  count_lines "/var/log/keystone/keystone.log" "Total expired tokens removed"

}

keystone_check_${CHECK_MODE}
unset count_lines
