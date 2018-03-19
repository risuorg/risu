#!/usr/bin/env bash
# Description: This script contains common functions to be used by citellus plugins
#
# Copyright (C) 2017  Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)
# Copyright (C) 2018  Mikel Olasagasti Uranga (mikel@redhat.com)
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

__osp_version_with_nova(){
    PKG=$(is_pkg openstack-nova-common)
    case ${PKG} in
        openstack-nova-common-2014.*) OSP=6 ;;
        openstack-nova-common-2015.*) OSP=7 ;;
        openstack-nova-common-12.*) OSP=8 ;;
        openstack-nova-common-13.*) OSP=9 ;;
        openstack-nova-common-14.*) OSP=10 ;;
        openstack-nova-common-15.*) OSP=11 ;;
        openstack-nova-common-16.*) OSP=12 ;;
        openstack-nova-common-17.*) OSP=13 ;;
        openstack-nova-common-18.*) OSP=14 ;;
        *) OSP=0 ;;
    esac
    echo ${OSP}
}

__osp_version_with_cinder(){
    PKG=$(is_pkg openstack-cinder)
    case ${PKG} in
        openstack-cinder-2014.*) OSP=6 ;;
        openstack-cinder-2015.*) OSP=7 ;;
        openstack-cinder-7.*) OSP=8 ;;
        openstack-cinder-8.*) OSP=9 ;;
        openstack-cinder-9.*) OSP=10 ;;
        openstack-cinder-10.*) OSP=11 ;;
        openstack-cinder-11.*) OSP=12 ;;
        openstack-cinder-12.*) OSP=13 ;;
        openstack-cinder-13.*) OSP=14 ;;
        *) OSP=0 ;;
    esac
    echo ${OSP}
}

discover_osp_version(){
    NOVA=$(__osp_version_with_nova)
    if [[ "x$NOVA" != "x0" ]]; then
        echo ${NOVA};
    else
        echo $(__osp_version_with_cinder)
    fi
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
        13) echo "queens" ;;
        14) echo "rocky" ;;
        *) echo "not recognized" ;;
    esac
}
