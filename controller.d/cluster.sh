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

# Cluster check
# Ref: 

echo "+--------------------------------------------+"
echo "|             Checking HA Cluster            |"
echo "+--------------------------------------------+"

# Checking the number of nodes in the cluster.

NUM_NODES=$(cat ${DIRECTORY}/sos_commands/pacemaker/crm_mon_-1_-A_-n_-r_-t | sed -n -r -e 's/^([0-9])[ \t]+nodes.*/\1/p')
if [ "${NUM_NODES}" -eq  "3" ]
then
  good "The nodes in cluster are equal to 3."
else
  bad "There are ${NUM_NODES} in cluster."
fi
