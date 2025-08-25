#!/bin/bash
# Copyright (C) 2021-2023 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

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

# long_name: Checks if nas_secure_file_{operations,permissions} is enabled
# description: Checks if non recommended nas_secure_file_operation and nas_secure_file_permissions are enabled for NFS and NetApp drivers
# priority: 750

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

# Actually run the check
is_required_file "${RISU_ROOT}/etc/cinder/cinder.conf"

ERRORMSGTRUE=$"Detected nas_secure options as true"
ERRORMSGAUTO=$"Detected nas_secure options as auto"
ERRORMSGNULL=$"Detected no nas_secure options, means working as auto"
ERRORMSGCINDERFILE=$"Check .cinderSecureEnvIndicator files on share root"
ERRORMSGNASSECURE=$"nas_secure_file_* options may cause permissions problems with snapshots, live migration and other operations"

# Check agains the following drivers
DRIVERMATCH="NfsDriver|NetAppDriver"

DRIVER=$(grep -E "$DRIVERMATCH" "${RISU_ROOT}/etc/cinder/cinder.conf" -c)

if [[ "x$DRIVER" != "x0" ]]; then

    OPERATIONS=$(grep ^nas_secure_file_operations "${RISU_ROOT}/etc/cinder/cinder.conf" | cut -d "=" -f2 | sed 's/^[ \t]*//' | tail -n1 | tr '[:upper:]' '[:lower:]')
    PERMISSIONS=$(grep ^nas_secure_file_permissions "${RISU_ROOT}/etc/cinder/cinder.conf" | cut -d "=" -f2 | sed 's/^[ \t]*//' | tail -n1 | tr '[:upper:]' '[:lower:]')

    if [[ "x$OPERATIONS" == "xtrue" ]] || [[ "x$PERMISSIONS" == "xtrue" ]]; then
        echo ${ERRORMSGTRUE} >&2
        echo ${ERRORMSGNASSECURE} >&2
        exit ${RC_FAILED}
    elif [[ "x$OPERATIONS" == "xauto" ]] || [[ "x$PERMISSIONS" == "xauto" ]]; then
        echo ${ERRORMSGAUTO} >&2
        echo ${ERRORMSGCINDERFILE} >&2
        exit ${RC_OKAY}
    elif [[ "x$OPERATIONS" == "x" ]] || [[ "x$PERMISSIONS" == "x" ]]; then
        echo ${ERRORMSGNULL} >&2
        echo ${ERRORMSGCINDERFILE} >&2
        exit ${RC_OKAY}
    else
        exit ${RC_OKAY}
    fi
else
    exit ${RC_OKAY}
fi
