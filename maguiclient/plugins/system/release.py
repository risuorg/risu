#!/usr/bin/env python
# encoding: utf-8
#
# Copyright (C) 2018  Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)
# Description: Plugin for checking RH Release across hosts

from __future__ import print_function

try:
    import citellusclient.shell as citellus
except:
    import shell as citellus

# Load i18n settings from citellus
_ = citellus._

extension = "release"


def init():
    """
    Initializes module
    :return: List of triggers for Plugin
    """
    ids = citellus.getids(include=['/metadata/system/release.sh'])
    return ids


def run(data, quiet=False):  # do not edit this line
    """
    Executes plugin
    :param quiet: reduce amount of data returned
    :param data: data to process
    :return: returncode, out, err
    """

    returncode = citellus.RC_OKAY

    message = ''
    for ourdata in data:
        # 'err' in this case should be always equal to the md5sum of the file so that we can report the problem
        err = []
        for sosreport in data[ourdata]['sosreport']:
            err.append(data[ourdata]['sosreport'][sosreport]['err'])

        if len(sorted(set(err))) != 1:
            message = _("Hosts contains different releases of operating system and can cause issues.")
            returncode = citellus.RC_FAILED

    out = ''
    err = message
    return returncode, out, err


def help():  # do not edit this line
    """
    Returns help for plugin
    :return: help text
    """

    commandtext = _("This plugin checks uniform releasing of OS across sosreports")
    return commandtext
