#!/bin/bash
# Copyright (C) 2017   Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

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


checksettings(){
FILE=${CITELLUS_ROOT}/etc/ceilometer/ceilometer.conf

if [ ! -f $FILE ];
then
    # Skip test if file is missing
    echo "$FILE does not exist" >&2
    exit 2
fi

RC=0

if [ ${RELEASE} -gt 7 ];
then
    for string in alarm_history_time_to_live event_time_to_live metering_time_to_live;
    do
        # check for string
        grep -qe ^${string} $FILE
        result=$?
        if [ "$result" -ne "0" ];
        then
            echo "$string missing on file" >&2
            RC=1
        else
            if [ $(grep -e ^${string} $FILE|cut -d "=" -f2) -le 0 ];
            then
                RC=1
                grep -e ^${string} $FILE >&2
            fi
        fi
    done
else
    for string in time_to_live;
    do
        if [ $(grep -e ^${string} $FILE|cut -d "=" -f2) -le 0 ];
        then
            RC=1
            grep -e ^${string} $FILE >&2
        fi
    done
fi
}


# Actually run the check

{ if [ "x$CITELLUS_LIVE" = "x0" ];  then
  # Check which version we are using
  if [ -f ${CITELLUS_ROOT}/installed-rpms ];
  then
    VERSION=$(grep "openstack-nova-common" "${CITELLUS_ROOT}/installed-rpms")
    RELEASE=$(discover_version)
    checksettings
    exit $RC
  else
    echo "Missing required file /installed-rpms" >&2
    exit 2
  fi
fi } >&2

{ if [ "x$CITELLUS_LIVE" = "x1" ];  then
  # Check which version we are using
  VERSION=$(rpm -qa | grep "openstack-nova-common")
  discover_version
  RELEASE=$(discover_version)
  checksettings
  exit $RC
fi } >&2
