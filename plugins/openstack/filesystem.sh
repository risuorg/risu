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

# Filesystem check
REFNAME="Filesystem module"

function filesystem_check_live(){

# Checking the ammount of disk space used.
  DISK_USE=$(read -d '' -ra df_arr < <(LC_ALL=C df -P /); echo "${df_arr[11]}")
  if [[ ${DISK_USE%%%*} -ge "75" ]]
  then
    bad "Filesystem more than ${DISK_USE} full."
  else
    good "Filesystem is at ${DISK_USE}."
  fi
    
}

function filesystem_check_sosreport(){

# A minimum of 40 GB of available disk space.
if [ -e "${DIRECTORY}/df" ]
then
  DISK_USE=$(cat "${DIRECTORY}"/df | awk '/dev.*\/$/{print $5}')
  if [[ ${DISK_USE%%%*} -ge "75" ]]
  then
    bad "Filesystem more than ${DISK_USE} full."
  else
    good "Filesystem is at ${DISK_USE}."
  fi
else
  warn "Missing file ${DIRECTORY}/df"
fi

}

# Filesystem check
filesystem_check_${CHECK_MODE}
