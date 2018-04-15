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

# long_name: Reports packages documented to be deprecated in RHEL 8
# description: Reports in-use packages that will be deprecated in next major release
# priority: 1

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

RELEASE=$(discover_rhrelease)

[[ "${RELEASE}" -eq '0' ]] && echo "RH release undefined" >&2 && exit ${RC_SKIPPED}

if [[ "${RELEASE}" -gt "7" ]]; then
    echo "test not applicable to EL8 releases or higher" >&2
    exit ${RC_SKIPPED}
fi

flag=0

echo "Following packages will be deprecated in RHEL8:" >&2

for package in authconfig pam_pkcs11 pam_krb5 openldap-servers mod_auth_kerb python-kerberos python-krbV python-requests-kerberos hesiod mod_nss mod_revocator ypserv ypbind portmap yp-tools nss-pam-ldapd mesa-private-llvm libdbi libdbi-drivers sendmail dmraid rsyslog-libdbi tcp_wrappers libcxgb3 cxgb3 libvirt-daemon-driver-lxc libvirt-daemon-lxc libvirt-login-shell; do
    is_rpm ${package} >&2 && flag=1
done

if [[ "$flag" -eq "1" ]]; then
    echo $"Check RHEL7.5 deprecation notice" >&2
    exit ${RC_FAILED}
fi

exit ${RC_OKAY}
