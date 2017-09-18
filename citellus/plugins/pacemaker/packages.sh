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

# we can run this against fs snapshot or live system

# Check which unitfile to use
if [ "x$CITELLUS_LIVE" = "x0" ];  then
  if [ -f "${CITELLUS_ROOT}/sos_commands/systemd/systemctl_list-units" ]; then
    UNITFILE="${CITELLUS_ROOT}/sos_commands/systemd/systemctl_list-units"
  elif [ -f "${CITELLUS_ROOT}/sos_commands/systemd/systemctl_list-units_--all" ]; then
    UNITFILE="${CITELLUS_ROOT}/sos_commands/systemd/systemctl_list-units_--all"
  fi
fi

if [ "x$CITELLUS_LIVE" = "x1" ];  then
  pacemaker_status=$(systemctl is-active pacemaker || :)
  if [ "$pacemaker_status" = "active" ]; then
    PCS_VERSION=$(rpm -qa pacemaker* | sed -n -r -e 's/^pacemaker.*-1.1.([0-9]+)-.*$/\1/p')
    for package in ${PCS_VERSION}
    do
      if [[ "${package}" -lt "15" ]]
      then
        echo "outdated pacemaker packages <1.1.15" >&2
        exit $RC_FAILED
      fi
    done
    exit $RC_OKAY
  else
    echo "pacemaker is not running on this node" >&2
    exit $RC_SKIPPED
  fi
elif [ "x$CITELLUS_LIVE" = "x0" ];  then
  if [ ! -f "${CITELLUS_ROOT}/installed-rpms" ]; then
    echo "file /installed-rpms not found." >&2
    exit $RC_SKIPPED
  else
    PCS_VERSION=$(sed -n -r -e 's/^pacemaker.*-1.1.([0-9]+)-.*$/\1/p' "${CITELLUS_ROOT}/installed-rpms")
    if grep -q "pacemaker.*active" "${UNITFILE}"; then
      for package in ${PCS_VERSION}
      do
        if [[ "${package}" -lt "15" ]]
        then
          echo "outdated pacemaker packages <1.1.15" >&2
          exit $RC_FAILED
        fi
      done
      exit $RC_OKAY
    else
      echo "pacemaker is not running on this node" >&2
      exit $RC_SKIPPED
    fi
  fi
fi
