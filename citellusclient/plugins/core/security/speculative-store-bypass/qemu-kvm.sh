#!/bin/bash

# Copyright (C) 2018  Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)

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

# long_name: Checks for fixed qemu-kvm package
# description: Checks if package is affected of Speculative Store Bypass
# priority: 400

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

exitoudated(){
    echo "Please do check https://access.redhat.com/security/vulnerabilities/ssbd for guidance" >&2
}

RELEASE=$(discover_rhrelease)
[[ "${RELEASE}" -eq '0' ]] && echo "RH release undefined" >&2 && exit ${RC_SKIPPED}

if [[ "${RELEASE}" -eq "7" ]]; then
    exitoudated
    is_required_rpm_over qemu-kvm qemu-kvm-1.5.3-156.el7_5.2
    is_required_rpm_over qemu-img qemu-img-1.5.3-156.el7_5.2
    is_required_rpm_over qemu-kvm-common qemu-kvm-common-1.5.3-156.el7_5.2
    is_required_rpm_over qemu-kvm-tools qemu-kvm-tools-1.5.3-156.el7_5.2
elif [[ "${RELEASE}" -eq "6" ]]; then
    exitoudated
    is_required_rpm_over qemu-guest-agent qemu-guest-agent-0.12.1.2-2.503.el6_9.6
    is_required_rpm_over qemu-img qemu-img-0.12.1.2-2.503.el6_9.6
    is_required_rpm_over qemu-kvm qemu-kvm-0.12.1.2-2.503.el6_9.6
    is_required_rpm_over qemu-kvm-tools qemu-kvm-tools-0.12.1.2-2.503.el6_9.6
fi
exit ${RC_OKAY}
