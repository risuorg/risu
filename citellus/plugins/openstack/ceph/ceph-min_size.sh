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

# Check if ceph cluster has default min_size or greater than 1.

if [ ! -f "${CITELLUS_ROOT}/etc/ceph/ceph.conf" ]; then
  echo "file /etc/ceph/ceph.conf not found." >&2
  exit 2
else
  MIN_SIZE=$(awk -F "=" '/^osd_pool_default_min_size/ {gsub (" ", "", $0); \
     print $2}' ${CITELLUS_ROOT}/etc/ceph/ceph.conf)
  if [ "${MIN_SIZE}" -le  "1" ]; then 
    echo "osd_pool_default_min_size is ${MIN_SIZE}" >&2
    exit 1
  else
    exit 0
  fi
fi
