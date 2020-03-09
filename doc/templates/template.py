#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Copyright (C) 2017, 2018 Pablo Iranzo Gómez <Pablo.Iranzo@redhat.com>

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
#
# long_name: plug long name for webui
# description: plug description
# bugzilla: bz url
# priority: 0<>1000 for likelihood to break your environment if this test reports fail
# kb: url-to-kbase

# Note a more pythonic way of running 'main' could be implemented by:
# Running tests as new functions like:
# def check_nova_debug(root=CITELLUS_ROOT) and calling it inside the live or not live checks (or both)


from __future__ import print_function

import os
import sys

import citellus


def errorprint(*args, **kwargs):
    """
    Prints to stderr a string
    :type args: String to print
    """
    print(*args, file=sys.stderr, **kwargs)


def runninglive():
    """
    Checks if we're running against a live environment
    :return: Bool
    """
    if os.environ["CITELLUS_LIVE"] == 1:
        return True
    elif os.environ["CITELLUS_LIVE"] == 0:
        return False


def exitcitellus(code=False, msg=False):
    """
    Exits back to citellus with errorcode and message
    :param msg: Message to report on stderr
    :param code: return code
    """
    if msg:
        errorprint(msg)
    sys.exit(code)


def main():
    """
    Performs checks and returns rc and err
    """

    # Base path to find files
    # CITELLUS_ROOT = os.environ["CITELLUS_ROOT"]

    if runninglive():
        # Running on LIVE environment

        # For example, next condition might be an existing file like:
        # os.path.exists(os.join.path(CITELLUS_ROOT,'/etc/nova/nova.conf'))
        if True:

            # Example: File does exist, check file contents or other checks
            if True:
                # Plugin tests passed
                exitcitellus(code=citellus.RC_OKAY)

            else:
                # Error with plugin tests

                # Provide messages on STDERR
                exitcitellus(
                    code=citellus.RC_FAILED, msg="There was an error because of 'xxx'"
                )
        else:
            # Plugin script skipped per conditions

            # Provide reason for skipping:
            exitcitellus(code=citellus.RC_SKIPPED, msg="Required file 'xxx' not found")

    elif not runninglive():
        # Running on snapshot/sosreport environment
        if True:
            if True:
                # Plugin tests passed
                exitcitellus(code=citellus.RC_OKAY)
            else:
                # Error with plugin tests

                # Provide messages on STDERR
                exitcitellus(
                    code=citellus.RC_FAILED, msg="There was an error because of 'xxx'"
                )
        else:
            # Plugin script skipped per conditions

            # Provide reason for skipping:
            exitcitellus(code=citellus.RC_SKIPPED, msg="Required file 'xxx' not found")


if __name__ == "__main__":
    main()
