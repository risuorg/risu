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

if [ ! "x$CITELLUS_LIVE" = "x1" ]; then
  echo "works on live-system only" >&2
  exit 2
fi

# We are checking for timed out, because swift-recon -r doesn't return exit
# code 1 if anything is wrong and neither contains error counter. meaning if 2
# nodes out of 3 reports good, then status is good but we can see time out
# connection to 3rd node.

if swift-recon -r | grep -q "timed out"; then
  swift-recon -r | grep "timed out" >&2
  exit 1
else
  exit 0
fi
