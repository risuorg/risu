#!/bin/bash

# Copyright (C) 2017   Robin Cernin (rcernin@redhat.com)

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

if [ ! -f "${CITELLUS_ROOT}/etc/glance/glance-api.conf" ]; then
  echo "file /etc/glance/glance-api.conf not found." >&2
  exit 2
fi
if grep -q "^image_size_cap" "${CITELLUS_ROOT}/etc/glance/glance-api.conf"; then
  IMAGE_SIZE_DEFAULT="1099511627776"
  IMAMGE_SIZE=$(awk -F "=" '/^image_size_cap/ {gsub (" ", "", $0); print $2}' \
              "${CITELLUS_ROOT}/etc/glance/glance-api.conf")

  if [ "${IMAGE_SIZE_DEFAULT}" -lt  "$IMAGE_SIZE_DEFAULT" ]; then
    echo "image_size_cap is less than 1TiB" >&2
    exit 1
  fi
  echo "image_size_cap is more than 1Tib" >&2
  exit 0
else
  echo "image_size_cap set to 1 TiB" >&2
  exit 0
fi
