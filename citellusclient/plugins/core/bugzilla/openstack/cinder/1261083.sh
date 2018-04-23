#!/bin/bash

# Copyright (C) 2018   Shatadru Bandyopadhyay (sbandyop@redhat.com)

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

# this can run against live and also any sort of snapshot of the filesystem

# long_name: Check lvm filter in compute nodes
# description: Verify lvm.conf filter/global_filter
# bugzilla: https://bugzilla.redhat.com/show_bug.cgi?id=1261083
# priority: 900

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

is_required_file "${CITELLUS_ROOT}/etc/lvm/lvm.conf"
is_required_pkg lvm2
show_warn () {
    echo $"lvm created inside cinder volume, might get exposed to the host system causing migration, guest boot or cinder actions to fail"  >&2
    echo $"https://bugzilla.redhat.com/show_bug.cgi?id=1261083" >&2
    exit ${RC_FAILED}
}
lvmetad=$(cat "${CITELLUS_ROOT}/etc/lvm/lvm.conf" |grep -i use_lvmetad|grep -iv "#"|cut -f2 -d "=" | tr -d '[:space:]' )
filter=$(cat "${CITELLUS_ROOT}/etc/lvm/lvm.conf" |grep -i filter|grep -iv global|grep -iv "#"|cut -f2 -d "="| tr -d '[:space:]')
global_filter=$(cat "${CITELLUS_ROOT}/etc/lvm/lvm.conf" |grep -i global_filter|grep -iv "#"|cut -f2 -d "="| tr -d '[:space:]')
filter_eval=$(echo $filter |egrep -i '\["r[/,|].\*[/,|][|]*"\]')
global_filter_eval=$(echo $global_filter |egrep -i '\["r[/,|].\*[/,|][|]*"\]')

if [[ "x${lvmetad}" = "x0" ]] ;then
    filter_in_use="filter"
    set_filter=$filter
else
    filter_in_use="global_filter"
    set_filter=$global_filter
fi

if ! is_process nova-compute; then
    echo "This check is specific to openstack compute node" >&2
    exit ${RC_SKIPPED}
fi
if [[ "${filter_in_use}" = "global_filter" ]];then
    if [[ -z  "$global_filter" ]] ; then
        flag=2
    elif [[  -z "$global_filter_eval" ]] ; then
            flag=1
    else
            flag=0
    fi
elif [[ "${filter_in_use}" = "filter" ]] ; then
    if [[ -z  "$filter" ]] ; then
        flag=2
    elif [[  -z "$filter_eval" ]] ; then
        flag=1
    else
        flag=0
    fi
fi

if [[ "$flag" == "2" ]]; then
        echo $"lvm $filter_in_use is not set in compute node"  >&2
        show_warn
elif  [[ "$flag" == "1" ]]; then
        echo $"lvm $filter_in_use is set, however it might not restrict all devices"  >&2
        echo "$filter_in_use is set to: $set_filter"  >&2
        show_warn
else
        exit ${RC_OKAY}
fi
