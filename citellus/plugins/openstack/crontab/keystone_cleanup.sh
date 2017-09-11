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

# this can run against live and also any sort of snapshot of the filesystem

# Version function cloned from version.sh
discover_version(){
case ${VERSION} in
  openstack-nova-common-2014.*) echo 6 ;;
  openstack-nova-common-2015.*) echo 7 ;;
  openstack-nova-common-12.*) echo 8 ;;
  openstack-nova-common-13.*) echo 9 ;;
  openstack-nova-common-14.*) echo 10 ;;
  openstack-nova-common-15.*) echo 11 ;;
  openstack-nova-common-16.*) echo 12 ;;
  *) echo 0 ;;
esac
}

# Find release to report which bug to check
if [ "x$CITELLUS_LIVE" = "x0" ];  then
  # Check which version we are using
  if [ -f ${CITELLUS_ROOT}/installed-rpms ];
  then
    VERSION=$(grep "openstack-nova-common" "${CITELLUS_ROOT}/installed-rpms")
    RELEASE=$(discover_version)
  else
    echo "missing required file /installed-rpms" >&2
    exit $RC_SKIPPED
  fi
elif [ "x$CITELLUS_LIVE" = "x1" ];  then
  # Check which version we are using
  VERSION=$(rpm -qa | grep "openstack-nova-common")
  RELEASE=$(discover_version)
fi

if [ ! -f "${CITELLUS_ROOT}/var/spool/cron/keystone" ]; then
  echo "file /var/spool/cron/keystone not found." >&2
  exit $RC_SKIPPED
fi
if ! awk '/keystone-manage token_flush/ && /^[^#]/ { print $0 }' "${CITELLUS_ROOT}/var/spool/cron/keystone"; then
  echo "crontab keystone cleanup is not set" >&2
  exit $RC_FAILED
elif awk '/keystone-manage token_flush/ && /^[^#]/ { print $0 }' "${CITELLUS_ROOT}/var/spool/cron/keystone"; then
  # Skip default crontab of 1 0 * * * as it might miss busy systems and fail to do later cleanups
  COUNT=$(awk '/keystone-manage token_flush/ && /^[^#]/ { print $0 }' "${CITELLUS_ROOT}/var/spool/cron/keystone" 2>&1|egrep  '^1 0'  -c)
  if [ "x$COUNT" = "x1" ];
  then
      echo -n "token flush not running every hour " >&2
      case ${RELEASE} in
        6) echo "https://bugzilla.redhat.com/show_bug.cgi?id=1470230" >&2 ;;
        7) echo "https://bugzilla.redhat.com/show_bug.cgi?id=1470227" >&2 ;;
        8) echo "https://bugzilla.redhat.com/show_bug.cgi?id=1470226" >&2 ;;
        9) echo "https://bugzilla.redhat.com/show_bug.cgi?id=1470221" >&2 ;;
        10) echo "https://bugzilla.redhat.com/show_bug.cgi?id=1469457" >&2 ;;
        *) echo "" >&2 ;;
      esac
      exit $RC_FAILED
  fi
  exit $RC_OKAY
fi
