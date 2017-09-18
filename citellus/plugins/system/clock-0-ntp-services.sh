#!/bin/bash

# Copyright (C) 2017 Robin Černín (rcernin@redhat.com)
# Modifications by Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)

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

# Load common functions
[ -f "${CITELLUS_BASE}/common-functions.sh" ] && . "${CITELLUS_BASE}/common-functions.sh"

# adapted from https://github.com/larsks/platypus/blob/master/bats/system/test_clock.bats

is_active() {
    systemctl is-active "$@" > /dev/null 2>&1
}

# Load common functions
[ -f "${CITELLUS_BASE}/common-functions.sh" ] && . "${CITELLUS_BASE}/common-functions.sh"

if [[ $CITELLUS_LIVE = 0 ]]; then
  if [ ! -f "${UNITFILE}" ]; then
    echo "file ${UNITFILE} not found." >&2
    exit $RC_SKIPPED
  else
    if grep -q "ntpd.*active" "${UNITFILE}"; then
      ntpd=1
    fi
    if grep -q "chronyd.*active" "${UNITFILE}"; then
      chronyd=1
    fi
    if [[ "x$ntpd" = "x1" && "x$chrony" = "x1" ]]; then
      echo "both chrony and ntpd are not active" >&2
      exit $RC_FAILED
    elif grep -q openstack- "${CITELLUS_ROOT}/installed-rpms"; then
        # Node is OSP system
        if [[ "x$chronyd" = "x1" ]]; then
            echo "chrony service is active, and it should not on OSP node" >&2
            exit $RC_FAILED
        elif [[ "x$ntpd" = "x1" ]]; then
            echo "no ntpd service is active" >&2
            exit $RC_FAILED
        else
            # One of chrony or ntpd are active, and this is not an OSP system, run the more complete tests
            if [[ "x$ntpd" = "x1" ]]; then
                . ${PLUGIN_BASEDIR}/clock-1-ntpd.sh
            elif [[ "x$chronyd" = "x1" ]]; then
                . ${PLUGIN_BASEDIR}/clock-1-chrony.sh
            fi
            exit $RC_FAILED
        fi
    else
        # This system has no openstack packages
        if [[ "x$ntpd" = "x1" ]]; then
            . ${PLUGIN_BASEDIR}/clock-1-ntpd.sh
        elif [[ "x$chronyd" = "x1" ]]; then
            . ${PLUGIN_BASEDIR}/clock-1-chrony.sh
        else
            echo "no chrony or ntpd services active" >&2
            exit $RC_FAILED
        fi

    fi
  fi
else
    ! is_active chronyd
    chronyd_active=$?

    ! is_active ntpd
    ntpd_active=$?

    if rpm -qa *openstack*|grep -q openstack-; then
        if [[ "x$ntpd_active" != "x0" ]]; then
            echo "no ntpd service is active" >&2
            exit $RC_FAILED
        elif [[ "x$chronyd_active" != "x0" ]]; then
            echo "chrony service is active, and it shoudln't on OSP node" >&2
            exit $RC_FAILED
        else
            # One of chrony or ntpd are active, and this is not an OSP system
            if [[ "x$ntpd_active" = "x0" ]]; then
                . ${PLUGIN_BASEDIR}/clock-1-ntpd.sh
            elif [[ "x$chronyd_active" = "x0" ]]; then
                . ${PLUGIN_BASEDIR}/clock-1-chrony.sh
            fi
            exit $RC_OKAY
        fi
    else
        # Non OSP node
        if (( ! (ntpd_active || chronyd_active) )); then
            echo "no ntp service is active" >&2
            exit $RC_FAILED
        fi

        if (( ntpd_active && chronyd_active )); then
            echo "both chrony and ntpd are not active" >&2
            exit $RC_FAILED
        fi
        exit $RC_OKAY
    fi
fi
