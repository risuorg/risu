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

# long_name: Report if virt_type is not set to kvm
# description: virt_type different to KVM could present performance issues vs kvm
# priority: 800


# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

FILE="${CITELLUS_ROOT}/etc/nova/nova.conf"
is_required_file ${FILE}

VTYPE=$(iniparser ${FILE} libvirt virt_type)

supported=1
case ${VTYPE} in
    "kvm")
        # do nothing
        ;;
    "")
        # do nothing
        ;;
    *)
        echo -n $"nova.conf virt_type is not default or kvm performance might be affected: " >&2
        echo "$VTYPE" >&2
        supported=0
        ;;
esac

if [[ "$supported" -ne "1" ]]; then
    exit ${RC_FAILED}
fi

exit ${RC_OKAY}
