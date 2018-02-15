#!/bin/bash

# Copyright (C) 2017   Contributor Name (contributor email)

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

# Example script that checks the redirect rule on director node is present.

# CITELLUS_LIVE=1 means we have specified --live in the CLI and we run
# against live system.
# CITELLUS_LIVE=0 means we are running against fs snapshot and another check
# for CITELLUS_ROOT is done.

# CITELLUS_ROOT if set contains the location of the fs snapshot.

if [ "x$CITELLUS_LIVE" = "x1" ];  then

  # First check to see if we are able to continue, in the live system its
  # a check that we run against the right host, in this case only director
  # node should be targeted.
  if  rpm -qa | grep -q "tripleo-heat-templates" && rpm -qa | grep -q \
  "python-tripleoclient"
  then
    # If the condition is met and we run against the desired host, we can then
    # check the required information. We check that the rule exists.
    if iptables -t nat -vnL | grep -q "REDIRECT.*169.254.169.254" ; then
      # exit ${RC_OKAY} means the framework is going to display 'okay' and move to another
      # script.
      exit ${RC_OKAY}
    else
      # Whenever we end with exit ${RC_FAILED}, we are printing out the content from the
      # stderr. In this case the message "rule is missing" is going to be printed out.
      echo "rule is missing" >&2
      exit ${RC_FAILED}
    fi
  else
    # If the condition fails and we are not running against the director, we skip the script.
    exit ${RC_SKIPPED}
  fi

elif [ "x$CITELLUS_LIVE" = "x0" ];  then

  # Second check is the same as the previous one, but only apply to fs snapshot,
  # because CITELLUS_LIVE=0 means we are running against fs snapshot.
  if grep -q "tripleo-heat-templates" "${CITELLUS_ROOT}/installed-rpms" && grep -q \
  "python-tripleoclient" "${CITELLUS_ROOT}/installed-rpms"
  then
    # To make sure the file exists and we can check it, the exit ${RC_SKIPPED} means we will skip the check
    # if the file is not present.
    if [ ! -f "${CITELLUS_ROOT}/sos_commands/networking/iptables_-t_nat_-nvL" ]; then
      echo "file /sos_commands/networking/iptables_-t_nat_-nvL not found." >&2
      exit ${RC_SKIPPED}
    fi
    # Here we check the rule in the file, if it exists we exit ${RC_OKAY} and script reports okay.
    if grep -q "REDIRECT.*169.254.169.254" "${CITELLUS_ROOT}/sos_commands/networking/iptables_-t_nat_-nvL" ; then
      exit ${RC_OKAY}
    else
      # Whenever we end with exit ${RC_FAILED}, we are printing out the content from the
      # stderr. In this case the message "rule is missing" is going to be printed out.
      echo "rule is missing" >&2
      exit ${RC_FAILED}
    fi
  else
    # If the condition fails and we are not running against the director, we skip the script.
    exit ${RC_SKIPPED}
  fi

fi
