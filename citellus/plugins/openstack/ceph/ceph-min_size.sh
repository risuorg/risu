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

# Check if ceph pools has correct min_size

mktempfile() {
  tmpfile=$(mktemp testsXXXXXX)
  tmpfile=$(readlink -f $tmpfile)
  trap "rm $tmpfile" EXIT
}

# Load common functions
[ -f "${CITELLUS_BASE}/common-functions.sh" ] && . "${CITELLUS_BASE}/common-functions.sh"

check_settings() {
  for pool in $(sed -n -r -e 's/^pool.*\x27(.*)\x27.*$/\1/p' $1); do
    MIN_SIZE=$(sed -n -r -e "s/^pool.*'$pool'.*min_size[ \t]([0-9]).*$/\1/p" $1)
    SIZE=$(sed -n -r -e "s/^pool.*'$pool'.*\ssize[ \t]([0-9]).*$/\1/p" $1)
    if [ -z "$SIZE" ] || [ -z "$MIN_SIZE" ]; then
      echo "error could not parse size or min_size." >&2
      exit $RC_FAILED
    fi
    _MIN_SIZE="$(( (SIZE/2) + 1 ))"

    if [ "${MIN_SIZE}" -lt  "${_MIN_SIZE}" ]; then
      echo "pool '$pool' min_size ${MIN_SIZE}" >&2
      flag=1
    fi
  done
  [[ "x$flag" = "x" ]] && exit $RC_OKAY || exit $RC_FAILED
}

if [ "x$CITELLUS_LIVE" = "x0" ];  then
  if [ ! -f "${UNITFILE}" ]; then
    echo "file ${CITELLUS_ROOT} not found." >&2
    exit $RC_SKIPPED
  else
    if grep -q "ceph-mon.*active" "${UNITFILE}"; then
      if [ ! -f "${CITELLUS_ROOT}/sos_commands/ceph/ceph_osd_dump" ]; then
        echo "file /sos_commands/ceph/ceph_osd_dump not found." >&2
        exit $RC_SKIPPED
      else
        check_settings "${CITELLUS_ROOT}/sos_commands/ceph/ceph_osd_dump"
      fi
    else
      echo "no ceph integrated" >&2
      exit $RC_SKIPPED
    fi
  fi
elif [ "x$CITELLUS_LIVE" = "x1" ]; then
  if hiera -c /etc/puppet/hiera.yaml enabled_services | egrep -sq ceph_mon; then
    mktempfile
    ceph osd dump > $tmpfile
    check_settings $tmpfile
  else
    echo "no ceph integrated" >&2
    exit $RC_SKIPPED
  fi
fi
