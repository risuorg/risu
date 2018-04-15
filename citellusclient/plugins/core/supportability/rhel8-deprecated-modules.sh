#!/bin/bash

# Copyright (C) 2018 Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)

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

# long_name: Reports modules documented to be deprecated in RHEL 8
# description: Reports in-use modules that will be deprecated in next major release
# priority: 1

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

#is_required_file ${CITELLUS_BASE}/etc/redhat-release
RELEASE=$(discover_rhrelease)
[[ "${RELEASE}" -eq '0' ]] && echo "RH release undefined" >&2 && exit ${RC_SKIPPED}

if [[ ${RELEASE} -gt 7 ]]; then
    echo "test not applicable to EL8 releases or higher" >&2
    exit ${RC_SKIPPED}
fi

if [[ ${CITELLUS_LIVE} -eq 0 ]]; then
    FILE="${CITELLUS_ROOT}/lsmod"
elif [[ ${CITELLUS_LIVE} -eq 1 ]];then
    FILE=$(mktemp)
    trap "rm ${FILE}" EXIT
    lsmod > ${FILE}
fi

flag=0

echo "Following modules will be deprecated in RHEL8:" >&2

for module in 3w-9xxx 3w-sas aic79xx aoe arcmsr acard-ahci sata_mv sata_nv sata_promise sata_qstor sata_sil sata_sil24 sata_sis sata_svw sata_sx4 sata_uli sata_via sata_vsc bfa cxgb3 cxgb3i hptiop isci iw_cxgb3 mptbase mptctl mptsas mptscsih mptspi mtip32xx mvsas mvumi osd libosd osst pata_acpi pata_ali pata_amd pata_arasan_cf pata_artop pata_atiixp pata_atp867x pata_cmd64x pata_cs5536 pata_hpt366 pata_hpt37x pata_hpt3x2n pata_hpt3x3 pata_it8213 pata_it821x pata_jmicron pata_marvell pata_netcell pata_ninja32 pata_oldpiix pata_pdc2027x pata_pdc202xx_old pata_piccolo pata_rdc pata_sch pata_serverworks pata_sil680 pata_sis pata_via pdc_adma pm80xx pmcraid qla3xxx stex sx8 ufshcd; do
    egrep "^${module}" "${FILE}" >&2
    if [[ "$?" -eq "0" ]]; then
        flag=1
    fi
done

if [[ "${flag}" -eq "1" ]]; then
    echo $"Check RHEL7.5 module deprecation notice" >&2
    exit ${RC_FAILED}
fi

exit ${RC_OKAY}
