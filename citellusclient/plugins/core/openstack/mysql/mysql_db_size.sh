#!/bin/bash
# Copyright (C) 2017   Pablo Caruana (pcaruana@redhat.com | pablo.caruana@gmail.com)
# Copyright (C) 2018   Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)
#
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

# long_name: Database size
# description: Checks for mysql database sizes
# priority: 500

# Load common functions
[[ -f "${CITELLUS_BASE}/common-functions.sh" ]] && . "${CITELLUS_BASE}/common-functions.sh"

# this can run against live or snapshot

if [[ ! "x$CITELLUS_LIVE" = "x1" ]]; then
    FILE="${CITELLUS_ROOT}/sos_commands/mysql/du_-s_.var.lib.mysql"
    is_required_file "${FILE}"

    # as with ONLINE, check for over 10Gb size
    LINES="$(awk '$1>10*1024*1024*1024 {print $1" "$2}' ${FILE})"

    if [[ ! -z ${LINES} ]]; then
        echo "Databases over 10gb" >&2
        awk '$1>10*1024*1024*1024 {print $1" "$2}' ${FILE} >&2
        exit ${RC_FAILED}
    else
        exit ${RC_OKAY}
    fi

else
    # This test requires mysql
    MYSQL_DIR="/var/lib/mysql"
    which mysql > /dev/null 2>&1
    RC=$?

    if [[ "x$RC" = "x0" ]]; then
        # Test connection to the db
        _test=$(mysql -u root -e exit 2>&1)
        RC=$?
        if [[ "x$RC" = "x0" ]]; then
            # Databases tables larger than 10 GB
            (
                mysql -t -u root -e 'SELECT table_schema AS db_name, table_name, ROUND(( data_length + index_length ) / ( 1024 * 1024 * 1024 ), 2) AS table_size_in_GB FROM information_schema.TABLES WHERE (DATA_LENGTH+INDEX_LENGTH)/ ( 1024 * 1024 * 1024 ) > 10;'
            ) >&2
        else
            echo -e "ERROR connecting to the database\n${_test}" >&2
            exit ${RC_SKIPPED}
        fi
    else
        echo "missing mysql binaries" >&2
        exit ${RC_SKIPPED}
    fi

    if [[ -d "${MYSQL_DIR}" ]]; then
        #Db disk usage for ibdata and ib_log kinds - gb unit size kinds could be associate with perfomance degradation and a potential need of table truncate operations
        (
            du -h --threshold=10G ${MYSQL_DIR}/* | sort -nr  | egrep -i "ibdata|ib_log"
        )  >&2
        exit ${RC_OKAY}
    else
        echo "$MYSQL_DIR doesn't exists" >&2
        exit ${RC_FAILED}
    fi
fi

echo "Test should have skipped before reaching this point" >&2
exit ${RC_FAILED}
