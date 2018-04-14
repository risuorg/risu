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

# long_name: freeradius correct_escapes and regular expressions
# description: Freeradius using 'correct_escapes' but with old regular expressions or the opposite
# priority: 400

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

is_required_pkg_over freeradius freeradius-3.0.5-0
is_required_file ${CITELLUS_ROOT}/etc/raddb/radiusd.conf

RADDB="${CITELLUS_ROOT}/etc/raddb"

OLD_REGEXP='\\\\\.'                             # \\.   e.g. "if (&User-Name =~ /\\.\\./ ) {"
NEW_REGEXP='[^\\]\\\.'                          # \.    e.g. "if (&User-Name =~ /\.\./ ) {"
REGEXP_MODE="^correct_escapes\\s*=\\s*true$"    # correct_escapes = true

# Function searching for "$INCLUDE <path>" statements and extracting <path> as absolute path
search_for_INCLUDE() {
    local file
    for file in $(awk '$1 ~ /\$INCLUDE/ { print $2 }' $*); do
        if [[ -d "$RADDB/$file" ]]; then
            # If file is a directoy, expand to files in that directory
            file=${file%/}                      # remove ending /
            local f
            for f in $(/bin/ls -1 ${RADDB}/${file}); do
                [ -f "$RADDB/$file/$f" ] || continue
                echo "$RADDB/$file/$f"
            done
        elif [[ -f "$RADDB/$file" ]]; then
            echo "$RADDB/$file"
        fi
    done
}

#
# Find out all files to grep into
#

ALL_FILES="$RADDB/radiusd.conf"
newfiles="$ALL_FILES"
while [ -n "$newfiles" ]; do
    files="$newfiles"
    newfiles=""
    for file in $(search_for_INCLUDE ${files}); do
        [[ " $ALL_FILES " != *\ ${file}\ * ]] || continue
        newfiles="${newfiles:+$newfiles }$file"
    done
    ALL_FILES="${ALL_FILES:+$ALL_FILES }$newfiles"
done

files_using_old_regex=()
files_using_new_regex=()
new_regexmode=0

for file in ${ALL_FILES}; do
    content="$(strip_and_trim ${file})"
    if echo "$content" | egrep -q "$OLD_REGEXP"; then
        files_using_old_regex=( "${files_using_old_regex[@]}" "$file" )
    fi
    if echo "$content" | egrep -q "$NEW_REGEXP"; then
        files_using_new_regex=( "${files_using_new_regex[@]}" "$file" )
    fi
    if echo "$content" | egrep -q "$REGEXP_MODE"; then
        new_regexmode=1
    fi
done

# There is an issue if:
# - 'old style' regex are found but regex mode is 'new style'
# - 'new style' regex are found but regex mode is 'old style'

if [[ -n "$files_using_old_regex" ]] && [[ ${new_regexmode} -eq 1 ]]; then
    echo $">>> new regex mode is used, but old regex style was found in some files" >&2
    printf '%s\n' "${files_using_old_regex[@]}" | sed "s#^${CITELLUS_ROOT}##g" >&2
    exit ${RC_FAILED}
elif [[ -n "$files_using_new_regex" ]] && [[ ${new_regexmode} -eq 0 ]]; then
    echo $">>> old regex mode is used, but new regex style was found in some files" >&2
    printf '%s\n' "${files_using_new_regex[@]}" | sed "s#^${CITELLUS_ROOT}##g" >&2
    exit ${RC_FAILED}
fi

# If the above conditions did not trigger RC_FAILED we are good.
exit ${RC_OKAY}
