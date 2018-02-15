#!/bin/bash

# Copyright (C) 2017   Robin Černín (rcernin@redhat.com)

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

# this can run against live and also any sort of snapshot of the filesystem

# long_name: Image upload size limit
# description: Report on low glance image_size_cap that might affect big image uploads
# priority: 300


# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

is_required_file "${CITELLUS_ROOT}/etc/glance/glance-api.conf"

if is_lineinfile "^image_size_cap" "${CITELLUS_ROOT}/etc/glance/glance-api.conf"; then
    IMAGE_SIZE_DEFAULT="1099511627776"
    IMAGE_SIZE=$(awk -F "=" '/^image_size_cap/ {gsub (" ", "", $0); print $2}' \
                "${CITELLUS_ROOT}/etc/glance/glance-api.conf")

    if [[ "${IMAGE_SIZE}" -lt  "${IMAGE_SIZE_DEFAULT}" ]]; then
        echo $"image_size_cap is less than 1TiB" >&2
        exit ${RC_FAILED}
    fi
    echo "image_size_cap is more than 1TiB" >&2
    exit ${RC_OKAY}
else
    echo "image_size_cap set to 1 TiB" >&2
    exit ${RC_OKAY}
fi
