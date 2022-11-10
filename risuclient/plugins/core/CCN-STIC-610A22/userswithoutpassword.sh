#!/bin/bash
# Copyright (C) 2019, 2021 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>
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

# long_name: Find users without password
# description: Find users without password
# priority: 900
# bugzilla: https://www.ccn-cert.cni.es/pdf/guias/series-ccn-stic/guias-de-acceso-publico-ccn-stic/6768-ccn-stic-610a22-perfilado-de-seguridad-red-hat-enterprise-linux-9-0/file.html

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

FILE="${RISU_ROOT}/etc/shadow"
is_required_file ${FILE}
flag=0

for user in $(cat ${FILE} | cut -d ":" -f 1,2); do
    USU=$(echo ${user} | cut -d ":" -f 1)
    PASS=$(echo ${user} | cut -d ":" -f 2)
    if [[ "x${PASS}" == "x" ]]; then
        flag=1
        echo "User ${USU} has empty password" >&2
    fi
done

if [[ ${flag} == "1" ]]; then
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
