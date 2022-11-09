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

# long_name: Check crypto policies applied
# description: Cheks applied crypto policies level
# priority: 900
# bugzilla: https://www.ccn-cert.cni.es/pdf/guias/series-ccn-stic/guias-de-acceso-publico-ccn-stic/6768-ccn-stic-610a22-perfilado-de-seguridad-red-hat-enterprise-linux-9-0/file.html

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

if [[ ${RISU_LIVE} -eq 0 ]]; then
    FILE="${RISU_ROOT}/sos_commands/crypto/update-crypto-policies_--show"
elif [[ ${RISU_LIVE} -eq 1 ]]; then
    FILE=$(mktemp)
    trap "rm ${FILE}" EXIT
    LANG=C update-crypto-policies --show >${FILE} 2>&1
fi

is_required_file ${FILE}

LEVEL=$(cat ${FILE} | xargs echo)

if [[ ${LEVEL} == "LEGACY" ]]; then
    echo "Security level for crypto policies is below recommended setting" >&2
    exit ${RC_FAILED}
fi

if [[ ${LEVEL} == "FUTURE" ]]; then
    echo "Security level for crypto policies is above recommended setting" >&2
    exit ${RC_INFO}
fi

exit ${RC_OKAY}
