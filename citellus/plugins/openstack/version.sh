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

# if we are running against fs snapshot we check installed-rpms

discover_version(){
case ${VERSION} in
  openstack-nova-common-2014.*) echo "juno" ;;
  openstack-nova-common-2015.*) echo "kilo" ;;
  openstack-nova-common-12.*) echo "liberty" ;;
  openstack-nova-common-13.*) echo "mitaka" ;;
  openstack-nova-common-14.*) echo "newton" ;;
  openstack-nova-common-15.*) echo "ocata" ;;
  openstack-nova-common-16.*) echo "pike" ;;
  *) echo "not recognized" ;;
esac
if [ ! -z $PACKSTACK ]; then
  echo "packstack detected"
  exit $RC_FAILED
fi
}

{ if [ "x$CITELLUS_LIVE" = "x0" ];  then
  # Check which version we are using
  VERSION=$(grep "openstack-nova-common" "${CITELLUS_ROOT}/installed-rpms")
  PACKSTACK=$(grep "openstack-packstack-" "${CITELLUS_ROOT}/installed-rpms")
  discover_version
fi } >&2

{ if [ "x$CITELLUS_LIVE" = "x1" ];  then
  # Check which version we are using
  VERSION=$(rpm -qa | grep "openstack-nova-common")
  PACKSTACK=$(rpm -qa | grep "openstack-packstack-")
  discover_version
fi } >&2
