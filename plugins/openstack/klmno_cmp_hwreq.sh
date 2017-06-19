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

# Checking Hardware Requirements
# Ref: https://access.redhat.com/documentation/en-us/red_hat_openstack_platform/10/html/director_installation_and_usage/chap-requirements#sect-Compute_Node_Requirements
REFNAME="Checking Hardware Requirements"
REFOSP_VERSION="kilo liberty mitaka newton ocata"
REFNODE_TYPE="compute"

# A minimum of 6 GB of RAM.
if [ -e "${DIRECTORY}/proc/meminfo" ]
then
  MEMTOTAL=$(cat "${DIRECTORY}"/proc/meminfo | sed -n -r -e 's/MemTotal:[ \t]+([0-9]+).*/\1/p')
  if [[ ${MEMTOTAL} -ge 6000000 ]]
    then
      good "Memory is greater than or equal to 6GB"
  else
    bad "Uh, oh, compute requires at least 6GB of RAM"
  fi
else
  warn "Missing file ${DIRECTORY}/proc/meminfo"
fi

# At least 4-core 64-bit x86 processor with support for the Intel 64 or AMD64 CPU extensions.

grep_file "${DIRECTORY}/proc/cpuinfo" "vmx\|svm"

if [ -e "${DIRECTORY}/proc/cpuinfo" ]
then
  TOTALCPU=$(cat "${DIRECTORY}"/proc/cpuinfo | grep "processor" | sort -u | wc -l)
  if [[ ${TOTALCPU} -ge 4 ]]
  then
    good "Checking minimum 4-core 64-bit x86 processor"
  else
    bad "Compute requires minimum 4-core 64-bit x86 processor"
  fi
else
  warn "Missing file ${DIRECTORY}/proc/cpuinfo"
fi

# A minimum of 40 GB of available disk space.
if [ -e "${DIRECTORY}/df" ]
then
  AVAILDISK=$(cat "${DIRECTORY}"/df | awk '/dev.*\/$/{print $2}')
  if [[ ${AVAILDISK} -ge 40000000 ]]
  then
    good "A minimum of 40GB of available disk space"
  else
    bad "Controller requires minimum of at least 40GB available disk space"
  fi
else
  warn "Missing file ${DIRECTORY}/df"
fi

if [ -e "${DIRECTORY}/df" ]
then
  FREEDISK=$(cat "${DIRECTORY}"/df | awk '/dev.*\/$/{print $4}')
  if [[ ${AVAILDISK} -ge 5000000 ]]
  then
    good "There is at least 5GB of free disk space"
  else
    bad "Check the disk space, might be running out soon."
  fi
else
  warn "Missing file ${DIRECTORY}/df"
fi

# A minimum of 2 x 1 Gbps Network Interface Cards. However, it is recommended to use a 10 Gbps interface for Provisioning network traffic, especially if provisioning a large number of nodes in your Overcloud environment.
