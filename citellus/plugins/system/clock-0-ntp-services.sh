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

# Load common functions
[ -f "${CITELLUS_BASE}/common-functions.sh" ] && . "${CITELLUS_BASE}/common-functions.sh"

# adapted from https://github.com/larsks/platypus/blob/master/bats/system/test_clock.bats

is_active() {
    systemctl is-active "$@" > /dev/null 2>&1
}

if [[ $CITELLUS_LIVE = 0 ]]; then
  if [ -z "${systemctl_list_units_file}" ]; then
    echo "file /sos_commands/systemd/systemctl_list-units not found." >&2
    echo "file /sos_commands/systemd/systemctl_list-units_--all not found." >&2
    exit $RC_SKIPPED
  else
    if ! grep -q "ntpd.* active" "${systemctl_list_units_file}"; then
      ntpd=1
    fi
    if ! grep -q "chronyd.* active" "${systemctl_list_units_file}"; then
      chronyd=1
    fi
    if [[ "x$ntpd" = "x1" && "x$chrony" = "x1" ]]; then
      echo "both chrony and ntpd are not active" >&2
      exit $RC_FAILED
    elif [[ "x$ntpd" = "x1" ]]; then
      echo "no ntpd service is active" >&2
      exit $RC_FAILED
    elif [[ "x$chronyd" = "x1" ]]; then
      echo "no chrony service is active" >&2
      exit $RC_FAILED
    else
      exit $RC_OKAY
    fi
  fi
else
  ! is_active chronyd
  chronyd_active=$?

  ! is_active ntpd
  ntpd_active=$?

  if (( ! (ntpd_active || chronyd_active) )); then
      echo "no ntp service is active" >&2
      exit $RC_FAILED
  fi

  if (( ntpd_active && chronyd_active )); then
      echo "both chrony and ntpd are not active" >&2
      exit $RC_FAILED
  fi
  exit $RC_OKAY
fi
