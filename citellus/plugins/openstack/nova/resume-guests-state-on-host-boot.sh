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

# this can run against live and also any sort of snapshot of the filesystem

config_files=( "${CITELLUS_ROOT}/etc/nova/nova.conf" \
          "${CITELLUS_ROOT}/etc/sysconfig/libvirt-guests" )

for config_file in "${config_files[@]}"; do
  if [ ! -f "${config_file}" ]; then
    echo "file ${config_file#$CITELLUS_ROOT} not found." >&2
    exit 2
  fi
done

# check if nova is configured to resume guests power state at hypervisor startup
# adapted from https://github.com/zerodayz/citellus/issues/59

LIBVIRTCONF="${CITELLUS_ROOT}/etc/sysconfig/libvirt-guests"
NOVACONF="${CITELLUS_ROOT}/etc/nova/nova.conf"
NOVASETTING="^resume_guests_state_on_host_boot"

LIBVIRTBOOT=$(grep ^ON_BOOT $LIBVIRTCONF | awk -F "=" '{print $2}' | sed 's/ //' | tr 'A-Z' 'a-z')
LIBVIRTOFF=$(grep ^ON_SHUTDOWN $LIBVIRTCONF | awk -F "=" '{print $2}' | sed 's/ //' | tr 'A-Z' 'a-z')
NOVASTRING=$(awk '/\[DEFAULT\]/,/\[api_database\]/' $NOVACONF | grep $NOVASETTING | awk -F "=" '{print $2}' \
            | sed 's/ //g' | tr 'A-Z' 'a-z')

if [[ "$LIBVIRTBOOT" == "ignore" && "$LIBVIRTOFF" == "shutdown" && "$NOVASTRING" == "true" ]]; then
  echo "compute node is configured to restore guests state at startup" >&2
  exit 0
else
  echo "compute node is NOT configured to restore guests state at startup" >&2
  exit 1
fi
