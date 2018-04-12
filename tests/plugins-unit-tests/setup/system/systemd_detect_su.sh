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
        # no real initscripts
        mkdir -p ${FOLDER}/usr/lib/systemd/system
        mkdir -p ${FOLDER}/etc/rc.d/init.d
        cat > "${FOLDER}/etc/rc.d/init.d/README" << EOF
Hello there!
I have su but I'm not a initscript
EOF
        cat > "${FOLDER}/etc/rc.d/init.d/not_a_initscript" << EOF
#!/bin/bash
su - rmetrich -c echo "Hello there!"
EOF
        ;;

    pass2)
        # some initscripts with 'su' and 'runuser', or 'runuser' only
        mkdir -p ${FOLDER}/usr/lib/systemd/system
        mkdir -p ${FOLDER}/etc/rc.d/init.d
        cat > "${FOLDER}/etc/rc.d/init.d/README" << EOF
Hello there!
I have su but I'm not a initscript
EOF
        cat > "${FOLDER}/etc/rc.d/init.d/not_a_initscript" << EOF
#!/bin/bash
su - rmetrich -c echo "Hello there!"
EOF
        cat > "${FOLDER}/etc/rc.d/init.d/initscript_with_both" << EOF
#!/bin/bash
# chkconfig: 345 97 03

if rhel7; then
    SU="/bin/runuser"
else
    SU="/bin/su"
fi
\$SU rmetrich -c echo "Hello there!"
EOF
        cat > "${FOLDER}/etc/rc.d/init.d/initscript_with_both_undetectable" << EOF
#!/bin/bash
# chkconfig: 345 97 03

if rhel7; then
    SU="/bin/runuser"
else
    SU="/bin/su"
fi
# This is an error, but cannot be detected
\$SU - rmetrich -c echo "Hello there!"
EOF
        cat > "${FOLDER}/etc/rc.d/init.d/initscript_with_runuser" << EOF
#!/bin/bash
# chkconfig: 345 97 03

runuser rmetrich -c echo "Hello there!"
EOF
        cat > "${FOLDER}/etc/rc.d/init.d/initscript_with_none" << EOF
#!/bin/bash
# chkconfig: 345 97 03

echo "Hello there!"
EOF
        ;;

    fail1)
        # some initscript with 'su'
        mkdir -p ${FOLDER}/usr/lib/systemd/system
        mkdir -p ${FOLDER}/etc/rc.d/init.d
        cat > "${FOLDER}/etc/rc.d/init.d/initscript_with_su" << EOF
#!/bin/bash
# chkconfig: 345 97 03

/bin/su rmetrich -c echo "Hello there!"
EOF
        ;;

    fail2)
        # some initscript with 'runuser - '
        mkdir -p ${FOLDER}/usr/lib/systemd/system
        mkdir -p ${FOLDER}/etc/rc.d/init.d
        cat > "${FOLDER}/etc/rc.d/init.d/initscript_with_runuser_dash" << EOF
#!/bin/bash
# chkconfig: 345 97 03

/bin/runuser - rmetrich -c echo "Hello there!"
EOF
        ;;

    fail3)
        # some initscript with 'runuser -l'
        mkdir -p ${FOLDER}/usr/lib/systemd/system
        mkdir -p ${FOLDER}/etc/rc.d/init.d
        cat > "${FOLDER}/etc/rc.d/init.d/initscript_with_runuser_l" << EOF
#!/bin/bash
# chkconfig: 345 97 03

/bin/runuser -l rmetrich -c echo "Hello there!"
EOF
        ;;

    falsepositive)
        # some initscript with 'runuser ... command -l'
        mkdir -p ${FOLDER}/usr/lib/systemd/system
        mkdir -p ${FOLDER}/etc/rc.d/init.d
        cat > "${FOLDER}/etc/rc.d/init.d/initscript_with_runuser_command_l" << EOF
#!/bin/bash
# chkconfig: 345 97 03

/bin/runuser rmetrich /usr/bin/bash -c /usr/bin/test -l /foo
EOF
        ;;

    skip)
        # no systemd
        mkdir -p ${FOLDER}/etc/rc.d/init.d
        cat > "${FOLDER}/etc/rc.d/init.d/myscript" << EOF
#!/bin/bash

case "\$1" in
start)
    ;;
stop)
    ;;
esac
EOF
        ;;

esac
