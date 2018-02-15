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

# long_name: Ring status
# description: Checks Swift ring status
# priority: 900

if [[ ! "x$CITELLUS_LIVE" = "x1" ]]; then
    echo "works on live-system only" >&2
    exit ${RC_SKIPPED}
fi

# We are checking swift.conf and rings md5sum against multiple hosts
# error on any of those is considered wrong.

# We are not grepping 0 error[s] because it could give false positives
# if swift.conf is ok but rings aren't.

if swift-recon --md5 | grep -q "[^0] error"; then
    swift-recon --md5 | grep "[^0] error" >&2
    exit ${RC_FAILED}
else
    exit ${RC_OKAY}
fi
