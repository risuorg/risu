#!/usr/bin/env bash
# Description: This script contains common functions to be used by risu plugins
#
# Copyright (C) 2019 Manuel Valle <manuvaldi@gmail.com>
# Copyright (C) 2018 Mikel Olasagasti Uranga <mikel@olasagasti.info>
# Copyright (C) 2017, 2019, 2020, 2021 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>
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

__osp_version_with_nova() {
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
    openstack-nova-common-19.*) OSP=15 ;;
    *) OSP=0 ;;
    esac
    echo ${OSP}
}

__osp_version_with_cinder() {
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
    openstack-cinder-14.*) OSP=15 ;;
    *) OSP=0 ;;
    esac
    echo ${OSP}
}

__osp_version_with_neutron() {
    PKG=$(is_pkg openstack-neutron)
    case ${PKG} in
    openstack-neutron-2014.*) OSP=6 ;;
    openstack-neutron-2015.*) OSP=7 ;;
    openstack-neutron-7.*) OSP=8 ;;
    openstack-neutron-8.*) OSP=9 ;;
    openstack-neutron-9.*) OSP=10 ;;
    openstack-neutron-10.*) OSP=11 ;;
    openstack-neutron-11.*) OSP=12 ;;
    openstack-neutron-12.*) OSP=13 ;;
    openstack-neutron-13.*) OSP=14 ;;
    openstack-neutron-14.*) OSP=15 ;;
    *) OSP=0 ;;
    esac
    echo ${OSP}
}

discover_osp_version() {
    GOTIT="NO"

    NOVA=$(__osp_version_with_nova)
    if [[ "x$NOVA" != "x0" ]]; then
        echo ${NOVA}
        GOTIT="YES"
    else
        CINDER=$(__osp_version_with_cinder)
    fi

    if [ "$GOTIT" != "YES" ] && [ "x$CINDER" != "x0" ]; then
        echo ${CINDER}
        GOTIT="YES"
    else
        NEUTRON=$(__osp_version_with_neutron)
    fi

    if [ "$GOTIT" != "YES" ] && [ "x$NEUTRON" != "x0" ]; then
        echo ${NEUTRON}
        GOTIT="YES"
    fi

    if [[ $GOTIT != "YES" ]]; then
        echo "0"
    fi
}

name_osp_version() {
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
    15) echo "stein" ;;
    *) echo "not recognized" ;;
    esac
}
