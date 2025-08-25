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

# long_name: Check environment variables
# description: Check critical environment variables
# priority: 400

# Load common functions
[[ -f "${RISU_BASE}/common-functions.sh" ]] && . "${RISU_BASE}/common-functions.sh"

ENV_ISSUES=0

if [[ "x$RISU_LIVE" == "x1" ]]; then
    # Check critical environment variables
    if [[ -z $PATH ]]; then
        echo "CRITICAL: PATH environment variable is not set" >&2
        ENV_ISSUES=$((ENV_ISSUES + 3))
    elif [[ $PATH != *"/usr/bin"* ]] || [[ $PATH != *"/bin"* ]]; then
        echo "WARNING: PATH may not contain essential directories" >&2
        ENV_ISSUES=$((ENV_ISSUES + 1))
    fi

    if [[ -z $HOME ]]; then
        echo "WARNING: HOME environment variable is not set" >&2
        ENV_ISSUES=$((ENV_ISSUES + 1))
    fi

    if [[ -z $USER && -z $LOGNAME ]]; then
        echo "WARNING: No user identification environment variables set" >&2
        ENV_ISSUES=$((ENV_ISSUES + 1))
    fi

    # Check for potentially dangerous environment variables
    if [[ -n $LD_PRELOAD ]]; then
        echo "WARNING: LD_PRELOAD is set: $LD_PRELOAD" >&2
        ENV_ISSUES=$((ENV_ISSUES + 1))
    fi

    if [[ -n $LD_LIBRARY_PATH ]]; then
        echo "INFO: LD_LIBRARY_PATH is set: $LD_LIBRARY_PATH" >&2
    fi

    # Check locale settings
    if [[ -z $LANG && -z $LC_ALL ]]; then
        echo "WARNING: No locale environment variables set" >&2
        ENV_ISSUES=$((ENV_ISSUES + 1))
    fi

    # Check timezone
    if [[ -z $TZ ]]; then
        if [[ ! -f "/etc/timezone" && ! -L "/etc/localtime" ]]; then
            echo "WARNING: No timezone configuration found" >&2
            ENV_ISSUES=$((ENV_ISSUES + 1))
        fi
    fi

    # Check for excessive environment variables
    ENV_COUNT=$(env | wc -l)
    if [[ $ENV_COUNT -gt 100 ]]; then
        echo "WARNING: Large number of environment variables: $ENV_COUNT" >&2
        ENV_ISSUES=$((ENV_ISSUES + 1))
    fi
else
    # Check sosreport for environment information
    if [[ -f "${RISU_ROOT}/environment" ]]; then
        # Check critical environment variables
        if ! grep -q "^PATH=" "${RISU_ROOT}/environment"; then
            echo "CRITICAL: PATH environment variable was not set" >&2
            ENV_ISSUES=$((ENV_ISSUES + 3))
        elif ! grep "^PATH=" "${RISU_ROOT}/environment" | grep -q "/usr/bin\|/bin"; then
            echo "WARNING: PATH may not have contained essential directories" >&2
            ENV_ISSUES=$((ENV_ISSUES + 1))
        fi

        if ! grep -q "^HOME=" "${RISU_ROOT}/environment"; then
            echo "WARNING: HOME environment variable was not set" >&2
            ENV_ISSUES=$((ENV_ISSUES + 1))
        fi

        if ! grep -q "^USER=\|^LOGNAME=" "${RISU_ROOT}/environment"; then
            echo "WARNING: No user identification environment variables were set" >&2
            ENV_ISSUES=$((ENV_ISSUES + 1))
        fi

        # Check for potentially dangerous environment variables
        if grep -q "^LD_PRELOAD=" "${RISU_ROOT}/environment"; then
            LD_PRELOAD_VAL=$(grep "^LD_PRELOAD=" "${RISU_ROOT}/environment" | cut -d= -f2-)
            echo "WARNING: LD_PRELOAD was set: $LD_PRELOAD_VAL" >&2
            ENV_ISSUES=$((ENV_ISSUES + 1))
        fi

        if grep -q "^LD_LIBRARY_PATH=" "${RISU_ROOT}/environment"; then
            LD_LIBRARY_PATH_VAL=$(grep "^LD_LIBRARY_PATH=" "${RISU_ROOT}/environment" | cut -d= -f2-)
            echo "INFO: LD_LIBRARY_PATH was set: $LD_LIBRARY_PATH_VAL" >&2
        fi

        # Check locale settings
        if ! grep -q "^LANG=\|^LC_ALL=" "${RISU_ROOT}/environment"; then
            echo "WARNING: No locale environment variables were set" >&2
            ENV_ISSUES=$((ENV_ISSUES + 1))
        fi

        # Check for excessive environment variables
        ENV_COUNT=$(wc -l <"${RISU_ROOT}/environment")
        if [[ $ENV_COUNT -gt 100 ]]; then
            echo "WARNING: Large number of environment variables: $ENV_COUNT" >&2
            ENV_ISSUES=$((ENV_ISSUES + 1))
        fi
    else
        echo "Environment information not found in sosreport" >&2
        exit $RC_SKIPPED
    fi
fi

# Check results
if [[ $ENV_ISSUES -gt 5 ]]; then
    echo "CRITICAL: Multiple environment variable issues found ($ENV_ISSUES)" >&2
    exit $RC_FAILED
elif [[ $ENV_ISSUES -gt 2 ]]; then
    echo "WARNING: Environment variable issues found ($ENV_ISSUES)" >&2
    exit $RC_FAILED
elif [[ $ENV_ISSUES -gt 0 ]]; then
    echo "INFO: Minor environment variable issues found ($ENV_ISSUES)" >&2
    exit $RC_OKAY
else
    echo "Environment variables appear to be configured properly" >&2
    exit $RC_OKAY
fi
