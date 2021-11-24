#!/bin/bash

# Copyright (C) 2018 Pablo Iranzo Gómez <Pablo.Iranzo@redhat.com>
# Copyright (C) 2017 Robin Černín <rcernin@redhat.com>

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

# long_name: plug long name for webui
# description: plug description
# bugzilla: bz url
# priority: 0<>1000 for likelihood to break your environment if this test reports fail
# kb: url-to-kbase

if [ "x$RISU_LIVE" = "x1" ]; then
    if true; then
        if true; then
            exit ${RC_OKAY}
        else
            exit ${RC_FAILED}
        fi
    else
        exit ${RC_SKIPPED}
    fi
elif [ "x$RISU_LIVE" = "x0" ]; then
    if true; then
        if true; then
            exit ${RC_OKAY}
        else
            exit ${RC_FAILED}
        fi
    else
        exit ${RC_SKIPPED}
    fi
fi
