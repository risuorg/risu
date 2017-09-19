#!/bin/bash

# Copyright (C) 2017   Robin Cernin (rcernin@redhat.com)

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

: ${CITELLUS_MAX_CLOCK_OFFSET:=1}

is_active() {
    systemctl is-active "$@" > /dev/null 2>&1
}

if [[ $CITELLUS_LIVE = 0 ]]; then
  if [ -z "${systemctl_list_units_file}" ]; then
    echo "file /sos_commands/systemd/systemctl_list-units not found." >&2
    echo "file /sos_commands/systemd/systemctl_list-units_--all not found." >&2
    exit $RC_SKIPPED
  else
    if ! grep -q "ntpd.* active" "${systemctl_list_units_file}"; then
      echo "no ntp service is active" >&2
      exit $RC_FAILED
    fi
  fi

  if [ ! -f "${CITELLUS_ROOT}/sos_commands/ntp/ntpq_-p" ]; then
    echo "file /sos_commands/ntp/ntpq_-p not found." >&2
    exit $RC_SKIPPED
  else
    if grep -q "Connection refused" "${CITELLUS_ROOT}/sos_commands/ntp/ntpq_-p"; then
      echo "ntpq: read: Connection refused" >&2
      exit $RC_FAILED
    fi
  fi
  if [ ! -f "${CITELLUS_ROOT}/etc/ntp.conf" ]; then
    echo "file /etc/ntp.conf not found." >&2
    exit $RC_SKIPPED
  else
    grep "^server" "${CITELLUS_ROOT}/etc/ntp.conf" >&2
  fi
  if [ ! -f "${CITELLUS_ROOT}/sos_commands/ntp/ntpq_-p" ]; then
    echo "file /sos_commands/ntp/ntpq_-p not found." >&2
    exit $RC_SKIPPED
  fi
  offset=$(awk '/^\*/ {print $9/1000}' "${CITELLUS_ROOT}/sos_commands/ntp/ntpq_-p")
  echo "clock offset is $offset" >&2

  RC=$(echo "$offset<${CITELLUS_MAX_CLOCK_OFFSET:-1} && \
      $offset>-${CITELLUS_MAX_CLOCK_OFFSET:-1}" | bc -l)

  [[ "x$RC" = "x0" ]] && exit $RC_OKAY || exit $RC_FAILED
else
  if ! is_active ntpd; then
      echo "ntpd is not active" >&2
      exit $RC_SKIPPED
  fi

  if ! [[ -x /usr/bin/bc ]]; then
      echo "this check requires /usr/bin/bc" >&2
      exit $RC_SKIPPED
  fi
  if [ ! -f "${CITELLUS_ROOT}/etc/ntp.conf" ]; then
    echo "file /etc/ntp.conf not found." >&2
    exit $RC_SKIPPED
  else
    grep "^server" "${CITELLUS_ROOT}/etc/ntp.conf" >&2
  fi
  if ! out=$(ntpq -c peers); then
      echo "failed to contact ntpd" >&2
      exit $RC_FAILED
  fi

  if ! awk '/^\*/ {sync=1} END {exit ! sync}' <<<"$out"; then
      echo "clock is not synchronized" >&2
      return 1
  fi

  offset=$(awk '/^\*/ {print $9/1000}' <<<"$out")
  echo "clock offset is $offset" >&2

  RC=$(echo "$offset<${CITELLUS_MAX_CLOCK_OFFSET:-1} && \
      $offset>-${CITELLUS_MAX_CLOCK_OFFSET:-1}" | bc -l)

  [[ "x$RC" = "x0" ]] && exit $RC_OKAY || exit $RC_FAILED
fi
