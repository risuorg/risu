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
# Ref: https://access.redhat.com/documentation/en-us/red_hat_openstack_platform/9/html-single/director_installation_and_usage/#sect-Undercloud_Requirements

# Red Hat Enterprise Linux 7.2 or later installed as the host operating system. 
REFNAME="Checking Hardware Requirements"

# A minimum of 16 GB of RAM.
if [ -e "${DIRECTORY}/proc/meminfo" ]
then
  MEMTOTAL=$(cat "${DIRECTORY}"/proc/meminfo | sed -n -r -e 's/MemTotal:[ \t]+([0-9]+).*/\1/p')
  if [[ ${MEMTOTAL} -ge 16000000 ]]
    then
      good "Memory is greater than or equal to 16GB"
  else
    bad "Uh, oh, undercloud requires at least 16GB of RAM"
  fi
else
  warn "Missing file ${DIRECTORY}/proc/meminfo"
fi

# An 8-core 64-bit x86 processor with support for the Intel 64 or AMD64 CPU extensions.

grep_file "${DIRECTORY}/proc/cpuinfo" "vmx\|svm"

if [ -e "${DIRECTORY}/proc/cpuinfo" ]
then
  TOTALCPU=$(cat "${DIRECTORY}"/proc/cpuinfo | grep "processor" | sort -u | wc -l)
  if [[ ${TOTALCPU} -ge 8 ]]
  then
    good "Checking minimum 8-core 64-bit x86 processor"
  else
    bad "Undercloud requires minimum 8-core 64-bit x86 processor"
  fi
else
  warn "Missing file ${DIRECTORY}/proc/cpuinfo"
fi

# A minimum of 40 GB of available disk space. Make sure to leave at least 10 GB free space before attempting an Overcloud deployment or update. This free space accommodates image conversion and caching during the node provisioning process.
if [ -e "${DIRECTORY}/df" ]
then
  AVAILDISK=$(cat "${DIRECTORY}"/df | awk '/dev.*\/$/{print $2}')
  if [[ ${AVAILDISK} -ge 40000000 ]]
  then
    good "A minimum of 40GB of available disk space"
  else
    bad "Undercloud requires minimum of at least 40GB available disk space"
  fi
else
  warn "Missing file ${DIRECTORY}/df"
fi

if [ -e "${DIRECTORY}/df" ]
then
  FREEDISK=$(cat "${DIRECTORY}"/df | awk '/dev.*\/$/{print $4}')
  if [[ ${AVAILDISK} -ge 10000000 ]]
  then
    good "A minimum of 10GB of free disk space"
  else
    bad "Undercloud requires minimum of at least 10GB free disk space"
  fi
else
  warn "Missing file ${DIRECTORY}/df"
fi

# A minimum of 2 x 1 Gbps Network Interface Cards. However, it is recommended to use a 10 Gbps interface for Provisioning network traffic, especially if provisioning a large number of nodes in your Overcloud environment.
