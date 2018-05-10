#!/bin/bash

# Copyright (C) 2018 Juan Luis de Sousa-Valadas (jdesousa@redhat.com)

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

# we can run this on fs snapshot or live system

# long_name: Etcd alternative names include the fqdn
# description: OpenShift and etcd versions compiled with golang >= 1.9
# priority: 400

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

if is_enabled etcd || is_enabled etcd_container ; then
    if openssl x509 -noout -text -in "${CITELLUS_ROOT}"/etc/etcd/server.crt |
        grep 'X509v3 Subject Alternative Name' -A1 |
        grep -q DNS:$(hostname -f) ; then

        echo 'OpenShift and NetworkManager are both enabled' >&2
        exit ${RC_OKAY}
    else
        echo 'The etcd certificate is missing the fqdn in the Subject Alternative names' >&2
        openssl x509 -noout -text -in "${CITELLUS_ROOT}"/etc/etcd/server.crt |
            grep 'X509v3 Subject Alternative Name' -A1  >&2

        exit ${RC_FAILED}
    fi
else
    echo 'etcd is not enabled' >&2
    exit ${RC_SKIPPED}
fi

