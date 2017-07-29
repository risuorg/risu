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

# adapted from https://github.com/larsks/platypus/blob/master/bats/system/test_clock.bats

is_active() {
    systemctl is-active "$@" > /dev/null 2>&1
}

if [ "x$CITELLUS_LIVE" = "x1" ]; then
  if ! is_active chronyd; then
    echo "chronyd is inactive" >&2
    exit 2
  fi
  chronyc tracking
  result=$?
  if [ "x$result" = "x0" ]; then
    echo "crhonyd is active" >&2
    # get offset
    offset=$(chronyc tracking | awk '/RMS offset/ {print $4}')
    echo "clock offset is ${offset:-unknown}" >&2
    # check offset is bigger than MAX_CLOCK_OFFSET +, MAX2_CLOCK_OFFSET -, default +/-1s
    result=$(( $($offset<${MAX_CLOCK_OFFSET:-1} && $offset>${MAX2_CLOCK_OFFSET:--1}) ))
    if [ "x$result" = "x1" ]; then
      exit 0
    else
      exit 1
    fi
  else
    exit 1
  fi
elif [ "x$CITELLUS_LIVE" = "x0" ]; then
  echo "works on live-system only" >&2
  exit 2
fi
