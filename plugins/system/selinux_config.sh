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

# selinux enforcing

if [ "x$CITELLUS_LIVE" = "x0" ];  then
  if [ ! -f "${CITELLUS_ROOT}/sos_commands/selinux/sestatus_-b" ]; then
    echo "file /sos_commands/selinux/sestatus_-bnot found." >&2
    exit 2
  fi

  grep -q "^Mode from config file:.*enforcing" "${CITELLUS_ROOT}/sos_commands/selinux/sestatus_-b" || exit 1
fi

if [ "x$CITELLUS_LIVE" = "x1" ]; then
  if ! sestatus -b | grep -q "^Mode from config file:.*enforcing"; then
    exit 1
  fi
fi
