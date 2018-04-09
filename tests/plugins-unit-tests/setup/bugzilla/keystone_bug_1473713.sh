#!/usr/bin/env bash
# Description: This script creates a validation environment for running the
#              test named like this one against and check correct behavior
#
# Copyright (C) 2017  Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)
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


# The way we're executed, $1 is the script name, $2 is the mode and $3 is the folder
FOLDER=$3

case $2 in
    pass)
        mkdir -p ${FOLDER}
        # Touch the systemctl command we check
        mkdir -p "$FOLDER/var/log/keystone/"
        echo "" > "$FOLDER/var/log/keystone/keystone.log"
        ;;

    fail)
        mkdir -p ${FOLDER}
        # Touch the systemctl command we check
        mkdir -p "$FOLDER/var/log/keystone/"
        echo "2017-08-29 14:01:53.159 352327 ERROR keystone DBDeadlock: (pymysql.err.InternalError) (1205, u'Lock wait timeout exceeded; try restarting transaction') [SQL: u'DELETE FROM token WHERE token.expires <= %(expires_1)s'] [parameters: {u'expires_1': datetime.datetime(2017, 8, 17, 21, 14, 41)}]" > "$FOLDER/var/log/keystone/keystone.log"
        ;;

    skipped)
        # Do nothing, the folder will be empty and test should be skipped
        ;;

    *)
        echo "Unexpected mode '$2'!"
        exit 2
        ;;
esac
