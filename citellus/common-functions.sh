#!/usr/bin/env bash
# Description: This script contains common functions to be used by citellus plugins
#
# Copyright (C) 2017  Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)
#
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


# Find the systemctl file that contains the units available as it changes depending on sosreport version
if [ "x$CITELLUS_LIVE" = "x0" ];  then
  if [ -f "${CITELLUS_ROOT}/sos_commands/systemd/systemctl_list-units" ]; then
    UNITFILE="${CITELLUS_ROOT}/sos_commands/systemd/systemctl_list-units"
  elif [ -f "${CITELLUS_ROOT}/sos_commands/systemd/systemctl_list-units_--all" ]; then
    UNITFILE="${CITELLUS_ROOT}/sos_commands/systemd/systemctl_list-units_--all"
  fi
fi

