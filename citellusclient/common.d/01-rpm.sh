#!/usr/bin/env bash
# Description: This script contains common functions to be used by citellus plugins
#
# Copyright (C) 2018  Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)
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


is_rpm(){
    if [ "x$CITELLUS_LIVE" = "x1" ]; then
        rpm -qa *$1*|egrep ^"$1"-[0-9]
    elif [ "x$CITELLUS_LIVE" = "x0" ]; then
        is_required_file "${CITELLUS_ROOT}/installed-rpms"
        awk '{print $1}' "${CITELLUS_ROOT}/installed-rpms"|egrep ^"$1"-[0-9]
    fi
}

is_required_rpm(){
    if ! is_rpm $1 ; then
        echo "required package $1 not found." >&2
        exit $RC_SKIPPED
    fi
}

is_rpm_over(){
    is_required_rpm $1
    flag=0
    VERSION=$(is_rpm $1|tail -1)
    if [[ "$#" -eq "3" ]]; then
        # $1 RPM
        # $2 MAJOR
        # $3 RELEASE
        MAJOR=$(echo ${VERSION} | sed -n -r -e "s/^$1.*-([0-9]+)-.*$/\1/p")
        RELEASE=$(echo ${VERSION} | sed -n -r -e "s/^$1.*-[0-9]+.[0-9]+-([0-9]+).*$/\1/p")

        if [[ "${MAJOR}" -ge "$2" ]]; then
            if [[ "${RELEASE}" -lt "$3" ]]; then
                flag=1
            fi
        else
            flag=1
        fi
    elif [[ "$#" -eq "4" ]]; then
        # $1 RPM
        # $2 MAJOR
        # $3 MINOR
        # $4 RELEASE
        MAJOR=$(echo ${VERSION} | sed -n -r -e "s/^$1.*-([0-9]+).[0-9]+-[0-9]+.*$/\1/p")
        MINOR=$(echo ${VERSION} | sed -n -r -e "s/^$1.*-[0-9]+.([0-9]+)-[0-9]+.*$/\1/p")
        RELEASE=$(echo ${VERSION} | sed -n -r -e "s/^$1.*-[0-9]+.[0-9]+-([0-9]+).*$/\1/p")

        if [[ "${MAJOR}" -ge "$2" ]]; then
            if [[ "${MINOR}" -ge "$3" ]]; then
                if [[ "${RELEASE}" -lt "$4" ]]; then
                    flag=1
                fi
            else
                flag=1
            fi
        else
            flag=1
        fi
    elif [[ "$#" -eq "5" ]]; then
        # $1 RPM
        # $2 MAJOR
        # $3 MID
        # $4 MINOR
        # $5 RELEASE
        MAJOR=$(echo ${VERSION} | sed -n -r -e "s/^$1.*-([0-9]+).[0-9]+.[0-9]+-[0-9]+.*$/\1/p")
        MID=$(echo ${VERSION} | sed -n -r -e "s/^$1.*-[0-9]+.([0-9]+).[0-9]+-[0-9]+.*$/\1/p")
        MINOR=$(echo ${VERSION} | sed -n -r -e "s/^$1.*-[0-9]+.[0-9]+.([0-9]+)-[0-9]+.*$/\1/p")
        RELEASE=$(echo ${VERSION} | sed -n -r -e "s/^$1.*-[0-9]+.[0-9]+.[0-9]+-([0-9]+).*$/\1/p")

        if [[ "${MAJOR}" -ge "$2" ]]; then
            if [[ "${MID}" -ge "$3" ]]; then
                if [[ "${MINOR}" -ge "$4" ]]; then
                    if [[ "${RELEASE}" -lt "$5" ]]; then
                        flag=1
                    fi
                else
                    flag=1
                fi
            else
                flag=1
            fi
        else
            flag=1
        fi
    else
        echo "invalid number of arguments $#" >&2
        exit 99
    fi
    if [[ "$flag" -eq "1" ]]; then
        # "package $1 version $VERSION is lower than required (${@:1})."
        return 1
    fi
    return 0

}

is_required_rpm_over(){
    is_required_rpm $1
    flag=0
    VERSION=$(is_rpm $1 2>&1|tail -1)
    if ! is_rpm_over "${@}" ; then
        echo "package $1 version $VERSION is lower than required (${@:1})." >&2
        exit $RC_FAILED
    fi
}
