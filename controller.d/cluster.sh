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
REFNAME="Checking HA Cluster"

# Checking the number of nodes in the cluster.
# Check which directory for cluster exists it's either cluster or pacemaker

for CLUSTER_DIRECTORY in "pacemaker" "cluster"; do

  if [ -d "${DIRECTORY}/sos_commands/${CLUSTER_DIRECTORY}" ]
  then
    PCS_DIRECTORY="${DIRECTORY}/sos_commands/${CLUSTER_DIRECTORY}"
  fi
done

if [ -z "${PCS_DIRECTORY}" ]
then
  warn "Missing directory ${DIRECTORY}/sos_commands/${CLUSTER_DIRECTORY}"
else
  NUM_NODES=$(sed -n -r -e 's/^([0-9])[ \t]+nodes.*/\1/p' "${PCS_DIRECTORY}/pcs_status")
  if [ "${NUM_NODES}" -eq  "3" ]
  then
    good "The nodes in cluster are equal to 3."
  else
    bad "There are ${NUM_NODES} in cluster."
  fi

  # Checking for stonith-enabled: true
  grep_file "${PCS_DIRECTORY}/pcs_config" "stonith-enabled:.*true"

  # Checking if there are any "Failed Actions" in the pcs_status
  grep_file_rev "${PCS_DIRECTORY}/pcs_status" "Failed Actions"

  # Checking if there are any "Stopped" services
  grep_file_rev "${PCS_DIRECTORY}/pcs_status" "Stopped"

fi
