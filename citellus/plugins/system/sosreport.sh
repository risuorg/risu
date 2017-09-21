#!/bin/bash

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

# we can run this against fs snapshot or live system

if [ "x$CITELLUS_LIVE" = "x1" ];  then
  VERSIONS=$(rpm -q sos | sed -n -r -e 's/sos.*-([0-9]+).([0-9]+)-([0-9]+).*$/\1-\2-\3/p')
elif [ "x$CITELLUS_LIVE" = "x0" ];  then
  VERSIONS=$(egrep 'sos' "${CITELLUS_ROOT}/installed-rpms"|awk '{print $1}'|sed -n -r -e 's/sos.*-([0-9]+).([0-9]+)-([0-9]+).*$/\1-\2-\3/p')
fi

exitoudated(){
  echo "outdated sosreport packages: please do update sos package to ensure required info is collected" >&2
  exit $RC_FAILED
}


if [ "x$VERSIONS" = "x" ]; then
  echo "required packages not found" >&2
  exit $RC_SKIPPED
else
    # Latest sos for el7.4 is 3.4-6.el7
    for package in ${VERSIONS}
    do
      MAJOR=$(echo $package|cut -d "-" -f1)
      MID=$(echo $package|cut -d "-" -f2)
      MINOR=$(echo $package|cut -d "-" -f3)
      if [[ "${MAJOR}" -ge "3" ]]
      then
        if [[ "${MID}" -ge "4" ]]
        then
          if [[ "${MINOR}" -lt "6" ]]
          then
            exitoudated
          fi
        else
          exitoudated
        fi
      else
        exitoudated
      fi
    done
    exit $RC_OKAY
  fi
fi
