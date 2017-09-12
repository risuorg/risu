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

# check baremetal node

if [ "x$CITELLUS_LIVE" = "x0" ];  then
  if [ ! -f "${CITELLUS_ROOT}/sos_commands/hardware/dmidecode" ]; then
    echo "file /sos_commands/hardware/dmidecode not found." >&2
    exit $RC_SKIPPED
  fi

  if grep -q "Product Name: VMware" "${CITELLUS_ROOT}/sos_commands/hardware/dmidecode"
  then
    echo "VMware" >&2
    exit $RC_FAILED
  elif grep -q "Product Name: VirtualBox" "${CITELLUS_ROOT}/sos_commands/hardware/dmidecode"
  then
    echo "Virtualbox" >&2
    exit $RC_FAILED
  elif grep -q "Product Name: KVM" "${CITELLUS_ROOT}/sos_commands/hardware/dmidecode"
  then
    echo "KVM" >&2
    exit $RC_FAILED
  elif grep -q "Product Name: Bochs" "${CITELLUS_ROOT}/sos_commands/hardware/dmidecode"
  then
    echo "Bosch" >&2
  else
    exit $RC_OKAY
  fi
elif [ "x$CITELLUS_LIVE" = "x1" ]; then
  if dmidecode | grep -q "Product Name: VMware"
  then
    echo "VMware" >&2
    exit $RC_FAILED
  elif dmidecode | grep -q "Product Name: VirtualBox"
  then
    echo "Virtualbox" >&2
    exit $RC_FAILED
  elif dmidecode | grep -q "Product Name: KVM"
  then
    echo "KVM" >&2
    exit $RC_FAILED
  elif dmidecode | grep -q "Product Name: Bochs"
  then
    echo "Bosch" >&2
  else
    exit $RC_OKAY
  fi
fi
