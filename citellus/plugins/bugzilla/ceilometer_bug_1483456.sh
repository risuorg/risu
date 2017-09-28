#!/bin/bash

# Copyright (C) 2017   Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)

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

# this can run against live and also any sort of snapshot of the filesystem

# Load common functions
[ -f "${CITELLUS_BASE}/common-functions.sh" ] && . "${CITELLUS_BASE}/common-functions.sh"

is_required_file "${CITELLUS_ROOT}/etc/nova/nova.conf"
is_required_file "${CITELLUS_ROOT}/etc/ceilometer/ceilometer.conf"
is_required_file "${CITELLUS_ROOT}/var/log/ceilometer/compute.log"

NOVAHOST=$(grep ^host.* "${CITELLUS_ROOT}/etc/nova/nova.conf"|cut -d "=" -f2|head -1)
CEILOHOST=$(grep ^host.* "${CITELLUS_ROOT}/etc/nova/nova.conf"|cut -d "=" -f2|head -1)
LOGHOST=$(cat "${CITELLUS_ROOT}/var/log/ceilometer/compute.log" |tr "& " "\n"|grep "^host="|cut -d "=" -f 2-|head -1)

if [[ -z "$NOVAHOST" ]];
then
  NOVAHOST="Fake1"
fi

if [[ -z "$CEILOHOST" ]];
then
  CEILOHOST="Fake2"
fi

if [[ -z "LOGHOST" ]];
then
  LOGHOST="Fake3"
fi

if [[ "x$NOVAHOST" != "x$CEILOHOST" ]]; then
  echo "https://bugzilla.redhat.com/show_bug.cgi?id=1483456" >&2
  exit $RC_FAILED
elif [[ "x$NOVAHOST" != "x$LOGHOST" ]]; then
  echo "https://bugzilla.redhat.com/show_bug.cgi?id=1483456" >&2
  exit $RC_FAILED
else
  exit $RC_OKAY
fi
