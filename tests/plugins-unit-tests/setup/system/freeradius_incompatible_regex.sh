#!/usr/bin/env bash
# Description: This script creates a validation environment for running the
#              test named like this one against and check correct behavior
#
# Copyright (C) 2018  Renaud Métrich (rmetrich@redhat.com)
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
    pass1)
        # new freeradius, uncustomized
        mkdir -p ${FOLDER}/etc/raddb
        echo "freeradius-3.0.13-8.el7_4.x86_64      Thu Mar  8 09:51:09 2018" > "${FOLDER}/installed-rpms"
        cat > "${FOLDER}/etc/raddb/radiusd.conf" << EOF
correct_escapes = true
\$INCLUDE proxy.conf
modules {
    \$INCLUDE mods-enabled/
}
policy {
    \$INCLUDE policy.d/
}
EOF
        mkdir -p ${FOLDER}/etc/raddb/mods-enabled ${FOLDER}/etc/raddb/policy.d
        cat > "${FOLDER}/etc/raddb/policy.d/filter" << EOF
filter_username {
    if (&User-Name =~ /\\.\\./ ) {
    }
}
EOF
        ;;

    pass2)
        # new freeradius with customized files (son from old package)
        mkdir -p ${FOLDER}/etc/raddb
        echo "freeradius-3.0.13-8.el7_4.x86_64      Thu Mar  8 09:51:09 2018" > "${FOLDER}/installed-rpms"
        cat > "${FOLDER}/etc/raddb/radiusd.conf" << EOF
\$INCLUDE proxy.conf
modules {
    \$INCLUDE mods-enabled/
}
policy {
    \$INCLUDE policy.d/
}
EOF
        mkdir -p ${FOLDER}/etc/raddb/mods-enabled ${FOLDER}/etc/raddb/policy.d
        cat > "${FOLDER}/etc/raddb/policy.d/filter" << EOF
filter_username {
    if (&User-Name =~ /\\\\.\\\\./ ) {
    }
}
EOF
        ;;

    fail1)
        # new freeradius with modified filter file (so, from old package)
        mkdir -p ${FOLDER}/etc/raddb
        echo "freeradius-3.0.13-8.el7_4.x86_64      Thu Mar  8 09:51:09 2018" > "${FOLDER}/installed-rpms"
        cat > "${FOLDER}/etc/raddb/radiusd.conf" << EOF
correct_escapes = true
\$INCLUDE proxy.conf
modules {
    \$INCLUDE mods-enabled/
}
policy {
    \$INCLUDE policy.d/
}
EOF
        mkdir -p ${FOLDER}/etc/raddb/mods-enabled ${FOLDER}/etc/raddb/policy.d
        cat > "${FOLDER}/etc/raddb/policy.d/filter" << EOF
filter_username {
    if (&User-Name =~ /\\\\.\\\\./ ) {
    }
}
EOF
        ;;

    fail2)
        # new freeradius with modified radiusd file (so, from old package)
        mkdir -p ${FOLDER}/etc/raddb
        echo "freeradius-3.0.13-8.el7_4.x86_64      Thu Mar  8 09:51:09 2018" > "${FOLDER}/installed-rpms"
        cat > "${FOLDER}/etc/raddb/radiusd.conf" << EOF
\$INCLUDE proxy.conf
modules {
    \$INCLUDE mods-enabled/
}
policy {
    \$INCLUDE policy.d/
}
EOF
        mkdir -p ${FOLDER}/etc/raddb/mods-enabled ${FOLDER}/etc/raddb/policy.d
        cat > "${FOLDER}/etc/raddb/policy.d/filter" << EOF
filter_username {
    if (&User-Name =~ /\\.\\./ ) {
    }
}
EOF
        ;;

    skip1)
        # no freeradius
        ;;

    skip2)
        # freeradius < targeted version
        mkdir -p ${FOLDER}
        echo "freeradius-3.0.4-8.el7_3.x86_64       Thu Mar  8 09:51:09 2018" > "${FOLDER}/installed-rpms"
        ;;

    skip3)
        # freeradius installed, but no /etc/raddb/radiusd.conf file
        mkdir -p ${FOLDER}
        echo "freeradius-3.0.13-8.el7_4.x86_64      Thu Mar  8 09:51:09 2018" > "${FOLDER}/installed-rpms"
        ;;

esac
