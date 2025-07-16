#!/bin/bash

# Copyright (C) 2024 Pablo Iranzo Gómez (Pablo.Iranzo@gmail.com)

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

# long_name: Check for systemd journal errors
# description: Check for errors in systemd journal logs
# priority: 890

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

ERROR_COUNT=0
WARNING_COUNT=0

if [[ "x$RISU_LIVE" == "x1" ]]; then
    # Check current journal for errors
    if command -v journalctl >/dev/null 2>&1; then
        # Get errors from the last 24 hours
        ERROR_COUNT=$(journalctl --since "24 hours ago" --priority=err --no-pager -q | wc -l)
        WARNING_COUNT=$(journalctl --since "24 hours ago" --priority=warning --no-pager -q | wc -l)

        if [[ $ERROR_COUNT -gt 0 ]]; then
            echo "Found $ERROR_COUNT errors in systemd journal (last 24 hours):" >&2
            journalctl --since "24 hours ago" --priority=err --no-pager -q | head -10 >&2
        fi

        if [[ $WARNING_COUNT -gt 20 ]]; then
            echo "Found $WARNING_COUNT warnings in systemd journal (last 24 hours)" >&2
        fi
    else
        echo "journalctl command not available" >&2
        exit $RC_SKIPPED
    fi
else
    # Check sosreport for journal entries
    if [[ -f "${RISU_ROOT}/journalctl" ]]; then
        ERROR_COUNT=$(grep -c "Priority: 3" "${RISU_ROOT}/journalctl" || echo "0")
        WARNING_COUNT=$(grep -c "Priority: 4" "${RISU_ROOT}/journalctl" || echo "0")

        if [[ $ERROR_COUNT -gt 0 ]]; then
            echo "Found $ERROR_COUNT errors in systemd journal from sosreport:" >&2
            grep "Priority: 3" "${RISU_ROOT}/journalctl" | head -10 >&2
        fi

        if [[ $WARNING_COUNT -gt 20 ]]; then
            echo "Found $WARNING_COUNT warnings in systemd journal from sosreport" >&2
        fi
    else
        echo "journalctl file not found in sosreport" >&2
        exit $RC_SKIPPED
    fi
fi

# Evaluate results
if [[ $ERROR_COUNT -gt 10 ]]; then
    echo "CRITICAL: Too many errors in systemd journal: $ERROR_COUNT" >&2
    exit $RC_FAILED
elif [[ $ERROR_COUNT -gt 0 ]]; then
    echo "WARNING: Found $ERROR_COUNT errors in systemd journal" >&2
    exit $RC_FAILED
elif [[ $WARNING_COUNT -gt 50 ]]; then
    echo "WARNING: High number of warnings in systemd journal: $WARNING_COUNT" >&2
    exit $RC_FAILED
else
    echo "Systemd journal shows no significant errors ($ERROR_COUNT errors, $WARNING_COUNT warnings)" >&2
    exit $RC_OKAY
fi
