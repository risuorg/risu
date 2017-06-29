#!/bin/bash
set -x

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

# Red Hat Enterprise Linux 7.2 or later installed as the host operating system. 
REFNAME="Checking Hardware Requirements"
REFOSP_VERSION="liberty mitaka"
REFNODE_TYPE="director"
REFSERVICE="mysql"

function mariadb_service_check_live(){

  mariadb_status=$(systemctl is-active mariadb.service || :)

  if [ "$mariadb_status" = "active" ]; then
    echo "Checking online"   
  fi

}

function mariadb_service_check_sosreport(){

  mariadb_status=$(systemctl is-active mariadb.service || :)

  if [ "$mariadb_status" = "active" ]; then
    echo "Checking online"   
  fi

}

mariadb_service_check_${CHECK_MODE}

# vim: ts=2 sw=2 et
