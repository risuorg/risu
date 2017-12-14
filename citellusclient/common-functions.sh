#!/bin/bash

# Description: This script contains common functions loader

# Copyright (C) 2017   Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)

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

# Load all common functions defined in common.d

export LANG=en_US

TEST_OKAY=$(tput setaf 2; echo "okay"; tput sgr0)
TEST_SKIPPED=$(tput setaf 3; echo "skipped"; tput sgr0)
TEST_FAILED=$(tput setaf 1; echo "failed"; tput sgr0)
TEST_WTF=$(tput setaf 1; echo "unexpected result"; tput sgr0)
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Add the extra vars we added on citelus.py to keep some
# level of compatibility for this script to keep working as fallback

export CITELLUS_BASE=${DIR}
export RC_OKAY=10
export RC_FAILED=20
export RC_SKIPPED=30
export TEXTDOMAIN='citellus'
export TEXTDOMAINDIR=${CITELLUS_BASE}/locale

for file in $(find ${CITELLUS_BASE}/common.d -maxdepth 1 -type f -name '*.sh');do
    . $file
done
