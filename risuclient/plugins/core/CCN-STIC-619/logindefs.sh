#!/bin/bash
# Copyright (C) 2019, 2020, 2021 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>
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

# long_name: Validate login definitions
# description: Ensure login configuration for CCN-STIC-619
# priority: 900
# bugzilla: https://www.ccn-cert.cni.es/pdf/guias/series-ccn-stic/guias-de-acceso-publico-ccn-stic/3674-ccn-stic-619-implementacion-de-seguridad-sobre-centos7/file.html

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

FILEDEFS="${RISU_ROOT}/etc/login.defs"
is_mandatory_file ${FILEDEFS}

OS=$(discover_os)

if [[ $OS == "debian" ]]; then
    RH_RELEASE=8
else
    RH_RELEASE=$(discover_rhrelease)
fi

# EL9 includes a new pwquality.config where some of the old options have been moved
if [[ ${RH_RELEASE} -gt 8 ]]; then
    FILEQUAL="${RISU_ROOT}/etc/security/pwquality.conf"
    is_mandatory_file ${FILEQUAL}
    CONFIG_DEFS="PASS_MAX_DAYS PASS_MIN_DAYS PASS_WARN_AGE"
    CONFIG_QUAL="minlen"
else
    CONFIG_DEFS="PASS_MAX_DAYS PASS_MIN_DAYS PASS_MIN_LEN PASS_WARN_AGE"
    CONFIG_QUAL=""
fi

for config in ${CONFIG_DEFS}; do
    if ! is_lineinfile ^${config}.* ${FILEDEFS}; then
        echo "Missing ${config} in ${FILEDEFS}" >&2
        exit ${RC_FAILED}
    fi
done
if [[ ${RH_RELEASE} -gt 8 ]]; then
    for config in ${CONFIG_QUAL}; do
        if ! is_lineinfile ^${config}.* ${FILEQUAL}; then
            echo "Missing ${config} in ${FILEQUAL}" >&2
            exit ${RC_FAILED}
        fi
    done
fi
PASS_MAX_DAYS=$(egrep ^PASS_MAX_DAYS ${FILEDEFS} | awk '{print $2}')
PASS_MIN_DAYS=$(egrep ^PASS_MIN_DAYS ${FILEDEFS} | awk '{print $2}')
PASS_WARN_AGE=$(egrep ^PASS_WARN_AGE ${FILEDEFS} | awk '{print $2}')

if [[ ${RH_RELEASE} -gt 8 ]]; then
    PASS_MIN_LEN=$(egrep ^minlen ${FILEQUAL} | cut -d "=" -f 2- | xargs echo)
else
    PASS_MIN_LEN=$(egrep ^PASS_MIN_LEN ${FILEDEFS} | awk '{print $2}')
fi
flag=0

if [[ ${PASS_MAX_DAYS} -gt "60" ]]; then
    echo "Maximum password age must be 60 days" >&2
    flag=1
fi

if [[ ${PASS_MIN_DAYS} -lt "15" ]]; then
    echo "Password must be kept for at least 15 days" >&2
    flag=1
fi

if [[ ${PASS_MIN_LEN} -lt "8" ]]; then
    echo "Password lenght must be at least 8 characters" >&2
    flag=1
fi

if [[ ${PASS_WARN_AGE} -lt "15" ]]; then
    echo "Password expiry notice must be at least 15 days" >&2
    flag=1
fi

if [[ ${flag} == "1" ]]; then
    exit ${RC_FAILED}
fi

exit ${RC_OKAY}
