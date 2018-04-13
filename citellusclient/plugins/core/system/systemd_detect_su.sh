#!/bin/bash

# Copyright (C) 2018   Renaud Métrich (rmetrich@redhat.com)

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

# long_name: 'su' is called in initscript, causing services to not be shut down correctly
# description: Detects the use of 'su' in initscripts (there may be false positives)
# priority: 400

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

# RHEL 7 and later (systemd)
is_required_directory "${CITELLUS_ROOT}/usr/lib/systemd/system"

# Function checking if a file is a 'real' initscript, by searching for various hints
is_initscript() {
    local file="$1"
    local content="$2"

    # If we find 'chkconfig: XYZ' or 'Provides: NAME', assume we have an
    # iniscript
    is_lineinfile '^#\s+(chkconfig|Provides):\s+.*$' ${file} && return 0

    # Otherwise, check for hints (shebang + presence of start/stop/status
    # keywords)
    #
    # Allocate 1 point for each item found. And declare as valid if confidence
    # >= 3 (half of the number of items + 1).
    local confidence=0
    # Search for shebang on first line
    if head -1 ${file} | grep -q '^#!'; then
        let confidence+=1
    fi

    local token
    for token in 'start' 'stop' 'status'; do
        if echo "$content" | egrep -qw "$token"; then
            let confidence+=1
        fi
    done

    [[ ${confidence} -ge 3 ]] && return 0

    # Failure
    return 1
}

files_having_runuser_l=()
files_having_su=()

for file in $(/bin/ls ${CITELLUS_ROOT}/etc/rc.d/init.d/*); do
    [[ -f "$file" ]] || continue

    content="$(strip_and_trim ${file})"
    is_initscript "$file" "$content" || continue

    su_found=0
    runuser_found=0
    runuser_l_found=0

    # Check for 'su'
    echo "$content" | egrep -qw "su" && let su_found+=1

    # Check for 'runuser'
    IFS=$'\n' read -rd '' -a lines <<< "$(echo "$content" | egrep "runuser")"
    for line in "${lines[@]}"; do
        let runuser_found+=1
        # Check for '-' or '-l', asssuming it will be at the runuser level
        egrep -qw -- "(-|-l)" <<< "$line" && let runuser_l_found+=1
    done

    # Finding 'runuser -l' needs a review
    [[ ${runuser_l_found} -ne 0 ]] && files_having_runuser_l=( "${files_having_runuser_l[@]}" "$file" )
    if [[ ${su_found} -ne 0 ]]; then
        # Finding both 'runuser' and 'su' indicates administrator likely 'fixed' the initscript
        [[ ${runuser_found} -ne 0 ]] && continue
        # Finding only 'su' needs a review
        files_having_su=( "${files_having_su[@]}" "$file" )
    fi
done

EXIT_STATUS=${RC_OKAY}

if [[ -n "$files_having_runuser_l" ]]; then
    echo $">>> 'runuser -l ...' or 'runuser - ...' was detected in some initscripts" >&2
    printf '%s\n' "${files_having_runuser_l[@]}" | sed "s#^${CITELLUS_ROOT}##g" >&2
    EXIT_STATUS=${RC_FAILED}
fi

if [[ -n "$files_having_su" ]]; then
    echo $">>> 'su' was detected in some initscripts" >&2
    printf '%s\n' "${files_having_su[@]}" | sed "s#^${CITELLUS_ROOT}##g" >&2
    EXIT_STATUS=${RC_FAILED}
fi

exit ${EXIT_STATUS}
