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

# Helper script to define location of various files.

if [ "x$CITELLUS_LIVE" = "x0" ];  then

  # List of systemd/systemctl_list-units files
  systemctl_list_units=( "${CITELLUS_ROOT}/sos_commands/systemd/systemctl_list-units" \
                         "${CITELLUS_ROOT}/sos_commands/systemd/systemctl_list-units_--all" )

  # find available one and use it, the ones at back with highest priority
  for file in ${systemctl_list_units[@]}; do
    [[ -f "${file}" ]] && systemctl_list_units_file="${file}"
  done

  # List of logs/journalctl files
  journal=( "${CITELLUS_ROOT}/sos_commands/logs/journalctl_--no-pager_--boot" \
            "${CITELLUS_ROOT}/sos_commands/logs/journalctl_--all_--this-boot_--no-pager" )

  # find available one and use it, the ones at back with highest priority
  for file in "${journal[@]}"; do
    [[ -f "${file}" ]] && journalctl_file="${file}"
  done

fi
