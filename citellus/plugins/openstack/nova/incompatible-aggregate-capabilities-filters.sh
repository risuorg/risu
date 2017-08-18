#!/bin/bash
# Copyright (C) 2017   Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


# Base: https://bugs.launchpad.net/nova/+bug/1279719

checksettings(){
FILE=${CITELLUS_ROOT}/etc/nova/nova.conf

if [ ! -f $FILE ];
then
    # Skip test if file is missing
    echo "${FILE} does not exist" >&2
    exit 2
fi
}


checksettings

export RC=0
COUNT=$(grep "^scheduler_default_filters" "${FILE}"|grep ComputeCapabilitiesFilter|grep AggregateInstanceExtraSpecsFilter|wc -l)
if [ ${COUNT} -ne 0 ];
then
    echo "Incompatible ComputeCapabilitiesFilter and AggregateInstanceExtraSpecsFilter in scheduler_default_filters at nova.conf" >&2
    export RC=1
fi

exit $RC
