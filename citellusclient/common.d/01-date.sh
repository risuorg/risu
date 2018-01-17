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


are_dates_diff_over(){
    # $1 days of difference
    # $2 date 1
    # $3 date 2

    diffdays="$1"
    date1="$2"
    date2="$3"

    EPOCH1="$(date -d "$date1" "+%s" 2>/dev/null)"
    if [[ "$?" == "1" ]]; then
        # failure when converting date, happened with one specific TZ, so let's approx by removing TZ
        EPOCH1=$(date -d "$(echo "$date1" |awk '{print $1" "$2" "$3" "$4" "$6}')" "+%s")
    fi

    EPOCH2="$(date -d "$date2" "+%s" 2>/dev/null)"
    if [[ "$?" == "1" ]]; then
        # failure when converting date, happened with one specific TZ, so let's approx by removing TZ
        EPOCH2=$(date -d "$(echo "$date2" |awk '{print $1" "$2" "$3" "$4" "$6}')" "+%s")
    fi

    if [[ ${EPOCH1} -gt ${EPOCH2} ]]; then
        DIFF="$(( ($EPOCH1 - $EPOCH2) ))"
    else
        DIFF="$(( ($EPOCH2 - $EPOCH1) ))"
    fi

    if [[ "$(( ($DIFF/(60*60*24)) ))" -gt "${diffdays}" ]]; then
        return 0
    else
        return 1
    fi
}
