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

discover_osp_version(){
    RPM=$(is_rpm openstack-nova-common)
    case ${RPM} in
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

name_osp_version(){
    VERSION=$(discover_osp_version)
    case ${VERSION} in
        6) echo "juno" ;;
        7) echo "kilo" ;;
        8) echo "liberty" ;;
        9) echo "mitaka" ;;
        10) echo "newton" ;;
        11) echo "ocata" ;;
        12) echo "pike" ;;
        *) echo "not recognized" ;;
    esac
}
