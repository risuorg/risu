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

# Check if ceph pg_num is optimal

mktempfile() {
  tmpfile_status=$(mktemp testsXXXXXX)
  tmpfile_status=$(readlink -f $tmpfile_status)
  tmpfile_osd_dump=$(mktemp testsXXXXXX)
  tmpfile_osd_dump=$(readlink -f $tmpfile_osd_dump)
  trap "rm $tmpfile_status $tmpfile_osd_dump" EXIT
}

check_settings() {
  PGS=$(sed -n -r -e 's/^pool.*pg_num\s([0-9]+).*$/\1/p' $1 | awk '{sum+=$1} END {print sum}')
  OSDS=$(sed -n -r -e 's/.*osdmap.*\s([0-9]+)\sosds.*$/\1/p' $2)
  for pool in $(sed -n -r -e 's/^pool.*\x27(.*)\x27.*$/\1/p' $1); do
    PG_NUM=$(sed -n -r -e "s/^pool.*'$pool'.*pg_num[ \t]([0-9]+).*$/\1/p" $1)
    SIZE=$(sed -n -r -e "s/^pool.*'$pool'.*\ssize[ \t]([0-9]+).*$/\1/p" $1)
    _PG_NUM="$(( PG_NUM * SIZE ))"
    PG_TOTAL+=$_PG_NUM
  done
  _PG_NUM=$(( PG_TOTAL / OSDS ))
  if [ $_PG_NUM -gt "100" ] && [ $_PG_NUM -lt "300" ]; then
      echo "pg_num count $_PG_NUM is optimal" >&2
  else
      echo "pg_num count $_PG_NUM is not optimal" >&2
      flag=1
  fi
  [[ "x$flag" = "x" ]] || exit 1
}

declare -i PG_TOTAL=0

if [ "x$CITELLUS_LIVE" = "x0" ];  then
  if [ ! -f "${CITELLUS_ROOT}/sos_commands/systemd/systemctl_list-units_--all" ]; then
    echo "file /sos_commands/systemd/systemctl_list-units_--all not found." >&2
    exit 2
  else
    if grep -q "ceph-mon.*active" "${CITELLUS_ROOT}/sos_commands/systemd/systemctl_list-units_--all"; then
      if [ ! -f "${CITELLUS_ROOT}/sos_commands/ceph/ceph_osd_dump" ]; then
        echo "file /sos_commands/ceph/ceph_osd_dump not found." >&2
        exit 2
      fi
      if [ ! -f "${CITELLUS_ROOT}/sos_commands/ceph/ceph_status" ]; then
        echo "file /sos_commands/ceph/ceph_status not found." >&2
        exit 2
      else
        check_settings "${CITELLUS_ROOT}/sos_commands/ceph/ceph_osd_dump" \
        "${CITELLUS_ROOT}/sos_commands/ceph/ceph_status"
      fi
    else
      echo "no ceph integrated" >&2
      exit 2
    fi
  fi
elif [ "x$CITELLUS_LIVE" = "x1" ]; then
  if hiera -c /etc/puppet/hiera.yaml enabled_services | egrep -sq ceph_mon; then
    mktempfile
    ceph -s > $tmpfile_status
    ceph osd dump > $tmpfile_osd_dump
    check_settings $tmpfile_osd_dump $tmpfile_status
  else
    echo "no ceph integrated" >&2
    exit 2
  fi
fi
