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

iniparser(){
    awk -F'=' -v topic="[$2]" -v key="$3" \
    '$0==topic { flag=1; next } /^\[/ { flag=0; next } \
    flag && tolower($1)~"^"key { gsub(" ", "") ; value=$2 } \
    END{ print tolower(value) }' $1
}

is_required_file(){
    for file in "$@"; do
        if [[ ! -f ${file} ]];  then
            # to remove the ${CITELLUS_ROOT} from the stderr.
            file=${file#${CITELLUS_ROOT}}
            echo "required file $file not found." >&2
            exit ${RC_SKIPPED}
        fi
    done
}

is_active(){
    if [ "x$CITELLUS_LIVE" = "x1" ]; then
        systemctl is-active "$1" > /dev/null 2>&1
    elif [ "x$CITELLUS_LIVE" = "x0" ]; then
        if [[ -f "${systemctl_list_units_file}" ]]; then
            grep -q "$1.* active" "${systemctl_list_units_file}"
        else
            echo "required systemd files not found." >&2
            exit ${RC_SKIPPED}
        fi
    fi
}

is_enabled(){
    if [ "x$CITELLUS_LIVE" = "x1" ]; then
        systemctl is-enabled "$1" > /dev/null 2>&1
    elif [ "x$CITELLUS_LIVE" = "x0" ]; then
        if [[ -f "${CITELLUS_ROOT}/sos_commands/systemd/systemctl_list-unit-files" ]]; then
            grep -q "$1.* enabled" "${CITELLUS_ROOT}/sos_commands/systemd/systemctl_list-unit-files"
        else
            echo "required systemd files not found." >&2
            exit ${RC_SKIPPED}
        fi
    fi
}

is_process(){
    if [ "x$CITELLUS_LIVE" = "x1" ];  then
        ps -elf | grep "$1" | grep -q -v grep
    elif [ "x$CITELLUS_LIVE" = "x0" ];  then
        grep -q "$1" "${CITELLUS_ROOT}/ps";
    fi
}

is_lineinfile(){
    # $1: regexp
    # $*: files
    [ -f "$2" ] && egrep -iq "$1" "${@:2}"
}

discover_rhrelease(){
    FILE="${CITELLUS_ROOT}/etc/redhat-release"
    is_required_file ${FILE}
    VERSION=$(cat ${FILE}|egrep -o "\(.*\)"|tr -d "()")
    case ${VERSION} in
        Maipo) echo 7 ;;
        Santiago) echo 6 ;;
        Tikanga) echo 5 ;;
        Nahant) echo 4 ;;
        Taroon) echo 3 ;;
        *) echo 0 ;;
    esac
}

# We do check on ID_LIKE so we can discard between dpkg or rpm access
discover_os(){
    FILE="${CITELLUS_ROOT}/etc/os-release"
    is_required_file ${FILE}
    if is_lineinfile ^ID_LIKE ${FILE};then
        OS=$(awk -F "=" '$1=="ID_LIKE" {print $2}' ${FILE}|tr -d '"')
    else
        OS=$(awk -F "=" '$1=="ID" {print $2}' ${FILE}|tr -d '"')
    fi

    if [ "$(echo ${OS}|tr ' ' '\n'|grep -i fedora|wc -l)" != "0" ]; then
        OS='fedora'
    elif [ "$(echo ${OS}|tr ' ' '\n'|grep -i debian|wc -l)" != "0" ]; then
        OS='debian'
    fi
    echo "${OS}"
}
