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

# this can run against live and also fs snapshot

if [ "x$CITELLUS_LIVE" = "x0" ];  then
  if grep -q nova-compute "${CITELLUS_ROOT}/ps";
  then
    echo "works only on controller node" >&2
    exit $RC_SKIPPED
  fi
elif [ "x$CITELLUS_LIVE" = "x1" ];  then
  if ps -elf | grep -q [n]ova-compute; then
    echo "works only on controller node" >&2
    exit $RC_SKIPPED
  fi
fi

if [ ! -f "${CITELLUS_ROOT}/var/log/keystone/keystone.log" ]; then
  echo "file /var/log/keystone/keystone.log not found." >&2
  exit $RC_SKIPPED
fi

RUNS=$(grep 'Total expired tokens removed' "${CITELLUS_ROOT}/var/log/keystone/keystone.log" | wc -l)

[[ "x${RUNS}" = "x" ]] && exit $RC_FAILED

if [[ "${RUNS}" -eq 0 ]]; then
    exit $RC_FAILED
elif [[ "${RUNS}" -ge 1 ]]; then
    echo "${RUNS}" >&2
    exit $RC_OKAY
fi
