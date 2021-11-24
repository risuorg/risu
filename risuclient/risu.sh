#!/bin/bash
# Copyright (C) 2017 Robin Černín <cerninr@gmail.com>
# Copyright (C) 2017, 2018, 2020, 2021 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

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

export LANG=en_US

TEST_OKAY=$(
    tput setaf 2
    echo "okay"
    tput sgr0
)
TEST_SKIPPED=$(
    tput setaf 3
    echo "skipped"
    tput sgr0
)
TEST_FAILED=$(
    tput setaf 1
    echo "failed"
    tput sgr0
)
TEST_INFO=$(
    tput setaf 5
    echo "info"
    tput sgr0
)
TEST_WTF=$(
    tput setaf 1
    echo "unexpected result"
    tput sgr0
)
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Add the extra vars we added on risu.py to keep some
# level of compatibility for this script to keep working as fallback

export CITELLUS_BASE=${DIR}
export RISU_BASE=${DIR}
export RC_OKAY=10
export RC_FAILED=20
export RC_SKIPPED=30
export RC_INFO=40
export TEXTDOMAIN='risu'
export TEXTDOMAINDIR=${RISU_BASE}/locale

scriptname() {
    echo "${0##*/}: $1" >&2
}

discover_tests() {
    find ${spec} -type d -execdir test -f {}/.risu_tests \; -exec find {} -type f -perm /u+x -print \;
}

show_stderr() {
    [ -s ${tmpdir}/stderr ] || continue
    sed 's/^/    /' ${tmpdir}/stderr && echo ""
}

show_logo() {
    echo "_________ .__  __         .__  .__                "
    echo "\_   ___ \|__|/  |_  ____ |  | |  |  __ __  ______"
    echo "/    \  \/|  \   __\/ __ \|  | |  | |  |  \/  ___/"
    echo "\     \___|  ||  | \  ___/|  |_|  |_|  |  /\___ \ "
    echo " \______  /__||__|  \___  >____/____/____//____  >"
    echo "        \/              \/                     \/ "
    echo $"                                                  "
}

show_help() {
    echo "Usage: ${0##*/} [-h] [--live] [DIRECTORY] [script folder] ... "
}

export RISU_LIVE="0"
export RISU_ROOT
export RISU_TMP=$(mktemp -d)
export CITELLUS_LIVE=${RISU_LIVE}
export CITELLUS_ROOT=${RISU_ROOT}
export CITELLUS_TMP=${RISU_TMP}

while :; do
    case "$1" in
    --live)
        RISU_LIVE="1"
        shift
        ;;
    -h | -\? | --help)
        show_help
        exit
        ;;
    --)
        shift
        break
        ;;
    -?*)
        echo "unknown option: ${1}" >&2
        exit ${RC_FAILED}
        ;;
    *)
        break
        ;;
    esac
done

tmpdir=$(mktemp -d testsXXXXXX)
tmpdir=$(readlink -f ${tmpdir})
trap "rm -rf ${tmpdir}" EXIT

if [ "x${RISU_LIVE}" = "x0" ]; then
    RISU_ROOT=$(cd $(dirname "$1") && pwd -P)/$(basename "$1")
    if [ ! -d "${RISU_ROOT}" ]; then
        show_help
        exit ${RC_FAILED}
    fi
    shift
fi

if [ -n "$*" ]; then
    specs=("$@")
else
    specs=($(find "${DIR}" -type d -execdir test -f {}/.risu_tests \; -print))
fi

for spec in "${specs[@]}"; do
    [ -d "$spec" ] || continue
    discover_tests "$spec" >>${tmpdir}/tests-unsorted
done

[ -e "$tmpdir/tests-unsorted" ] && sort -u ${tmpdir}/tests-unsorted >${tmpdir}/tests || exit ${RC_FAILED}

show_logo
test_count=$(wc -l <${tmpdir}/tests)
scriptname "found $test_count tests"
[[ ${RISU_LIVE} == 1 ]] && echo "mode: live" || echo "mode: fs snapshot $RISU_ROOT"

while read test; do
    echo -n "# $test: "
    (
        cd $(dirname ${test})
        ./$(basename ${test}) >${tmpdir}/stdout 2>${tmpdir}/stderr
    )
    result=$?

    if [[ ${result} -eq ${RC_OKAY} ]]; then
        echo ${TEST_OKAY}
    elif [[ ${result} -eq ${RC_SKIPPED} ]]; then
        echo ${TEST_SKIPPED}
    elif [[ ${result} -eq ${RC_FAILED} ]]; then
        echo ${TEST_FAILED}
        show_stderr
    elif [[ ${result} -eq ${RC_INFO} ]]; then
        echo ${TEST_INFO}
        show_stderr
    else
        echo ${TEST_WTF}
        show_stderr
    fi

done <${tmpdir}/tests
