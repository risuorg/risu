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

is_rpm_over(){
    # $1 RPM
    # $2 MAJOR
    # $3 MID
    # $4 MINOR
    is_required_rpm $1
    VERSION=$(is_rpm sos)
    MAJOR=$(echo ${VERSION} | sed -n -r -e "s/^$1.*-([0-9]+).[0-9]+-[0-9]+.*$/\1/p")
    MID=$(echo ${VERSION} | sed -n -r -e "s/^$1.*-[0-9]+.([0-9]+)-[0-9]+.*$/\1/p")
    MINOR=$(echo ${VERSION} | sed -n -r -e "s/^$1.*-[0-9]+.[0-9]+-([0-9]+).*$/\1/p")

    if [[ "${MAJOR}" -ge "$2" ]]; then
        if [[ "${MID}" -ge "$3" ]]; then
            if [[ "${MINOR}" -lt "$4" ]]; then
                echo "required package $1 version is lower than $MAJOR $MID $MINOR." >&2
                exit $RC_FAILED
            fi
        else
            echo "required package $1 version is lower than $MAJOR $MID $MINOR." >&2
            exit $RC_FAILED
        fi
    else
        echo "required package $1 version is lower than $MAJOR $MID $MINOR." >&2
        exit $RC_FAILED
    fi
}
