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

# long_name: Validate fstab configuration
# description: Validate fstab configuration for CCN-STIC-619
# priority: 900
# bugzilla: https://www.ccn-cert.cni.es/pdf/guias/series-ccn-stic/guias-de-acceso-publico-ccn-stic/3674-ccn-stic-619-implementacion-de-seguridad-sobre-centos7/file.html

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

FILE="${RISU_ROOT}/etc/fstab"
is_mandatory_file ${FILE}

# /boot checks
FS="/boot"
flagboot=0
if is_lineinfile "$FS" ${FILE}; then
    OPTIONS=$(cat ${FILE} | awk --assign fs="$FS" '$2 == fs {print $4}')
    for config in noauto noexec nodev nosuid ro; do
        if [[ $(echo ${OPTIONS} | grep ${config} | wc -l) == 0 ]]; then
            echo "Missing option ${config} for ${FS}" >&2
            flagboot=1
        fi
    done
fi

# /boot/efi checks
FS="/boot/efi"
flagbootefi=0
if is_lineinfile "$FS" ${FILE}; then
    OPTIONS=$(cat ${FILE} | awk --assign fs="$FS" '$2 == fs {print $4}')
    for config in umask=0077 shortname=winnt; do
        if [[ $(echo ${OPTIONS} | grep ${config} | wc -l) == 0 ]]; then
            echo "Missing option ${config} for ${FS}" >&2
            flagbootefi=1
        fi
    done
fi

# /usr checks
FS="/usr"
flagusr=0
if is_lineinfile "$FS" ${FILE}; then
    OPTIONS=$(cat ${FILE} | awk --assign fs="$FS" '$2 == fs {print $4}')
    for config in nodev ro; do
        if [[ $(echo ${OPTIONS} | grep ${config} | wc -l) == 0 ]]; then
            echo "Missing option ${config} for ${FS}" >&2
            flagusr=1
        fi
    done
fi

# /opt checks
FS="/opt"
flagopt=0
if is_lineinfile "$FS" ${FILE}; then
    OPTIONS=$(cat ${FILE} | awk --assign fs="$FS" '$2 == fs {print $4}')
    for config in nodev ro; do
        if [[ $(echo ${OPTIONS} | grep ${config} | wc -l) == 0 ]]; then
            echo "Missing option ${config} for ${FS}" >&2
            flagopt=1
        fi
    done
fi

# /var/log/audit checks
FS="/var/log/audit"
flagvarlogaudit=0
if is_lineinfile "$FS" ${FILE}; then
    OPTIONS=$(cat ${FILE} | awk --assign fs="$FS" '$2 == fs {print $4}')
    for config in noexec nodev nosuid rw; do
        if [[ $(echo ${OPTIONS} | grep ${config} | wc -l) == 0 ]]; then
            echo "Missing option ${config} for ${FS}" >&2
            flagvarlogaudit=1
        fi
    done
fi

# /var/log checks
FS="/var/log"
flagvarlog=0
if is_lineinfile "$FS" ${FILE}; then
    OPTIONS=$(cat ${FILE} | awk --assign fs="$FS" '$2 == fs {print $4}')
    for config in noexec nodev nosuid rw; do
        if [[ $(echo ${OPTIONS} | grep ${config} | wc -l) == 0 ]]; then
            echo "Missing option ${config} for ${FS}" >&2
            flagvarlog=1
        fi
    done
fi

# /var/www checks
FS="/var/www"
flagvarwww=0
if is_lineinfile "$FS" ${FILE}; then
    OPTIONS=$(cat ${FILE} | awk --assign fs="$FS" '$2 == fs {print $4}')
    for config in noexec nodev nosuid rw; do
        if [[ $(echo ${OPTIONS} | grep ${config} | wc -l) == 0 ]]; then
            echo "Missing option ${config} for ${FS}" >&2
            flagvarwww=1
        fi
    done
fi

# /var checks
FS="/var"
flagvar=0
if is_lineinfile "$FS" ${FILE}; then
    OPTIONS=$(cat ${FILE} | awk --assign fs="$FS" '$2 == fs {print $4}')
    for config in defaults nosuid; do
        if [[ $(echo ${OPTIONS} | grep ${config} | wc -l) == 0 ]]; then
            echo "Missing option ${config} for ${FS}" >&2
            flagvar=1
        fi
    done
fi

# /home checks
FS="/home"
flaghome=0
if is_lineinfile "$FS" ${FILE}; then
    OPTIONS=$(cat ${FILE} | awk --assign fs="$FS" '$2 == fs {print $4}')
    for config in noexec nodev nosuid rw; do
        if [[ $(echo ${OPTIONS} | grep ${config} | wc -l) == 0 ]]; then
            echo "Missing option ${config} for ${FS}" >&2
            flaghome=1
        fi
    done
fi

for check in flagboot flagbootefi flagusr flagopt flagvarlogaudit flagvarlog flagvarwww flagvar flaghome; do
    if [[ $(set | grep ^${check} | cut -d "=" -f2) != "0" ]]; then
        exit ${RC_FAILED}
    fi
done

exit ${RC_OKAY}
