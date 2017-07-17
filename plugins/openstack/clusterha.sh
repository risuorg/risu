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
REFNAME="ClusterHA module"
pacemaker_status=$(systemctl is-active pacemaker || :)

function clusterha_check_live(){

  # Checking the number of nodes in the cluster.
  # Check which directory for cluster exists it's either cluster or pacemaker

  if [ "$pacemaker_status" = "active" ]
  then
    NUM_NODES=$(pcs status | sed -n -r -e 's/^([0-9])[ \t]+nodes.*/\1/p')
    if [ "$echo $(( (NUM_NODES-1) % 2 ))" -eq  "0" ]
    then
      good "The nodes in cluster are equal to ${NUM_NODES}."
    else
      bad "There are ${NUM_NODES} in cluster."
    fi

    # Checking for stonith-enabled: true
    if pcs config | grep -q "stonith-enabled:.*true"
    then
      good "Found stonith-enabled: true in pcs config"
    else
      bad "stonig-enabled NOT found in pcs config"
    fi

    # Checking if there are any "Failed Actions" in the pcs_status
    if pcs status | grep -q "Failed Actions"
    then
      bad "Found Failed Actions in pcs status"
    else
      good "Failed Actions was NOT found in pcs status"
    fi

    # Checking if there are any "Stopped" services
    if pcs status | grep -q "Stopped"
    then
      bad "Stopped Actions in pcs status"
    else
      good "Stopped was NOT found in pcs status"
    fi

    # Check packages version
    PCS_VERSION=$(rpm -qa | sed -n -r -e 's/^pacemaker.*-1.1.([0-9]+)-.*$/\1/p')
    for package in ${PCS_VERSION}
    do
      if [[ "${package}" -lt "15" ]]
      then
	VERSION_CHECK="1"
      fi
    done
    if [[ "${VERSION_CHECK}" -eq "1" ]]
    then
      bad "Pacemaker packages are older than 1.1.15."
    else
      good "Pacemaker version is greater than or equal to 1.1.15."
    fi
  else
    continue

  fi


}


function clusterha_check_sosreport(){

  # Checking the number of nodes in the cluster.
  # Check which directory for cluster exists it's either cluster or pacemaker

  if grep -q "pacemaker.*active" "${DIRECTORY}/sos_commands/systemd/systemctl_list-units_--all"
  then
    for CLUSTER_DIRECTORY in "pacemaker" "cluster"; do

      if [ -d "${DIRECTORY}/sos_commands/${CLUSTER_DIRECTORY}" ]
      then
	PCS_DIRECTORY="${DIRECTORY}/sos_commands/${CLUSTER_DIRECTORY}"
      fi
    done

    if [ -z "${PCS_DIRECTORY}" ]
    then
      continue
    else

      NUM_NODES=$(sed -n -r -e 's/^([0-9])[ \t]+nodes.*/\1/p' "${PCS_DIRECTORY}/pcs_status")
      if [ "$echo $(( (NUM_NODES-1) % 2 ))" -eq  "0" ]
      then
	good "The nodes in cluster are equal to ${NUM_NODES}."
      else
	bad "There are ${NUM_NODES} in cluster."
      fi

      # Checking for stonith-enabled: true
      grep_file "${PCS_DIRECTORY}/pcs_config" "stonith-enabled:.*true"

      # Checking if there are any "Failed Actions" in the pcs_status
      grep_file_rev "${PCS_DIRECTORY}/pcs_status" "Failed Actions"

      # Checking if there are any "Stopped" services
      grep_file_rev "${PCS_DIRECTORY}/pcs_status" "Stopped"

      # Check packages version
      PCS_VERSION=$(sed -n -r -e 's/^pacemaker.*-1.1.([0-9]+)-.*$/\1/p' "${DIRECTORY}/installed-rpms")
      for package in ${PCS_VERSION}
      do
	if [[ "${package}" -lt "15" ]]
	then
	  VERSION_CHECK="1"
	fi
      done
      if [[ "${VERSION_CHECK}" -eq "1" ]]
      then
	bad "Pacemaker packages are older than 1.1.15."
      else
	good "Pacemaker version is greater than or equal to 1.1.15."
      fi
    fi
  else
    continue
  fi

}

# Cluster module
clusterha_check_${CHECK_MODE}

