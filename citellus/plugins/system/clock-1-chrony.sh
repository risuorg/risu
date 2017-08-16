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

: ${CITELLUS_MAX_CLOCK_OFFSET:=1}

is_active() {
    systemctl is-active "$@" > /dev/null 2>&1
}

if [[ $CITELLUS_LIVE = 0 ]]; then
  if [ ! -f "${CITELLUS_ROOT}/sos_commands/systemd/systemctl_list-units_--all" ]; then
    echo "file /sos_commands/systemd/systemctl_list-units_--all not found." >&2
    exit 2
  else
    if ! grep -q "chronyd.*active" "${CITELLUS_ROOT}/sos_commands/systemd/systemctl_list-units_--all"; then
      echo "no chrony service is active" >&2
      exit 1
    fi
  fi

  if [ ! -f "${CITELLUS_ROOT}/sos_commands/chrony/chronyc_tracking" ]; then
    echo "file /sos_commands/chrony/chronyc_tracking not found." >&2
    exit 2
  else
    if grep -q "Not synchronised" "${CITELLUS_ROOT}/sos_commands/chrony/chronyc_tracking"; then
      echo "clock is not synchronized" >&2
      exit 1
    fi
    offset=$(awk '/RMS offset/ {print $4}' "${CITELLUS_ROOT}/sos_commands/chrony/chronyc_tracking")
    echo "clock offset is $offset" >&2
    ((
    $(echo "$offset<${CITELLUS_MAX_CLOCK_OFFSET:-1} && \
    $offset>-${CITELLUS_MAX_CLOCK_OFFSET:-1}" | bc -l)
    ))
  fi
else
  if ! is_active chronyd; then
      echo "chronyd is not active"
      exit 2
  fi

  if ! [[ -x /usr/bin/bc ]]; then
      echo "this check requires /usr/bin/bc" >&2
      exit 2
  fi


  if ! out=$(chronyc tracking); then
      echo "clock is not synchronized" >&2
      return 1
  fi

  offset=$(awk '/RMS offset/ {print $4}' <<<"$out")
  echo "clock offset is $offset" >&2

  ((
  $(echo "$offset<${CITELLUS_MAX_CLOCK_OFFSET:-1} && \
      $offset>-${CITELLUS_MAX_CLOCK_OFFSET:-1}" | bc -l)
  ))
fi
