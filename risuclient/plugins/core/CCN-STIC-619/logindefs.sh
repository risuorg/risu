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

FILE="${RISU_ROOT}/etc/login.defs"
is_mandatory_file ${FILE}

for config in PASS_MAX_DAYS PASS_MIN_DAYS PASS_MIN_LEN PASS_WARN_AGE; do
    if ! is_lineinfile ^${config}.* ${FILE}; then
        echo "Missing ${config} in ${FILE}" >&2
        exit ${RC_FAILED}
    fi
done

PASS_MAX_DAYS=$(egrep ^PASS_MAX_DAYS ${FILE} | awk '{print $2}')
PASS_MIN_DAYS=$(egrep ^PASS_MIN_DAYS ${FILE} | awk '{print $2}')
PASS_MIN_LEN=$(egrep ^PASS_MIN_LEN ${FILE} | awk '{print $2}')
PASS_WARN_AGE=$(egrep ^PASS_WARN_AGE ${FILE} | awk '{print $2}')

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
