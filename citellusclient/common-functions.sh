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

if [ "x$CITELLUS_LIVE" = "x0" ];  then

    # List of systemd/systemctl_list-units files
    systemctl_list_units=( "${CITELLUS_ROOT}/sos_commands/systemd/systemctl_list-units" "${CITELLUS_ROOT}/sos_commands/systemd/systemctl_list-units_--all" )

    # find available one and use it, the ones at back with highest priority
    for file in ${systemctl_list_units[@]}; do
        [[ -f "${file}" ]] && systemctl_list_units_file="${file}"
    done

    # List of logs/journalctl files
    journal=( "${CITELLUS_ROOT}/sos_commands/logs/journalctl_--no-pager_--boot" "${CITELLUS_ROOT}/sos_commands/logs/journalctl_--all_--this-boot_--no-pager" )

    # find available one and use it, the ones at back with highest priority
    for file in "${journal[@]}"; do
        [[ -f "${file}" ]] && journalctl_file="${file}"
    done
fi

is_required_file() {
    for file in "$@"; do
        if [[ ! -f $file ]];  then
            # to remove the ${CITELLUS_ROOT} from the stderr.
            file=${file#$CITELLUS_ROOT}
            echo "required file $file not found." >&2
            exit $RC_SKIPPED
        fi
    done
}

is_active() {
    if [ "x$CITELLUS_LIVE" = "x1" ]; then
        systemctl is-active "$1" > /dev/null 2>&1
    elif [ "x$CITELLUS_LIVE" = "x0" ]; then
        if [[ -f "${systemctl_list_units_file}" ]]; then
            grep -q "$1.* active" "${systemctl_list_units_file}"
        else
            echo "required systemd files not found." >&2
            exit $RC_SKIPPED
        fi
    fi
}

is_rpm(){
    if [ "x$CITELLUS_LIVE" = "x1" ]; then
        rpm -qa *$1*|egrep ^"$1"-[0-9]
    elif [ "x$CITELLUS_LIVE" = "x0" ]; then
        awk '{print $1}' "${CITELLUS_ROOT}/installed-rpms"|egrep ^"$1"-[0-9]
    fi
}

is_required_rpm(){
    if ! is_rpm $1 ; then
        echo "required package $1 not found." >&2
        exit $RC_SKIPPED
    fi
}

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

is_process(){
    if [ "x$CITELLUS_LIVE" = "x1" ];  then
        ps -elf | grep -q "$1"
    elif [ "x$CITELLUS_LIVE" = "x0" ];  then
        grep -q "$1" "${CITELLUS_ROOT}/ps";
    fi
}

is_lineinfile(){
    # $1: regexp
    # $*: files
    [ -f "$2" ] && egrep -iq "$1" "${@:2}"
}
