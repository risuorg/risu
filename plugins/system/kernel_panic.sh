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

# Looks for the Kernel Out of Memory, panics and soft locks

flag=0
if [ $CITELLUS_LIVE -eq 0 ];  then
  if [ ! -f "${CITELLUS_ROOT}/sos_commands/logs/journalctl_--no-pager_--boot" ]; then
    echo "file /sos_commands/logs/journalctl_--no-pager_--boot not found." >&2
    exit 1
  fi

  if grep -q "oom-killer" "${CITELLUS_ROOT}/sos_commands/logs/journalctl_--no-pager_--boot"; then
    echo "oom-killer detected" >&2
    flag=1
  fi
  if grep -q "soft lockup" "${CITELLUS_ROOT}/sos_commands/logs/journalctl_--no-pager_--boot"; then
    echo "soft lockup detected" >&2
    flag=1
  fi
fi

if [ $CITELLUS_LIVE -eq 1 ]; then
  if journalctl -u kernel --no-pager --boot | grep -q "oom-killer"; then
    echo "soft lockup detected" >&2
    flag=1
  fi
  if journalctl -u kernel --no-pager --boot | grep -q "soft lockup"; then
    echo "soft lockup detected" >&2
    flag=1
  fi
fi
[ "$flag" = 0 ]
