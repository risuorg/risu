#!/usr/bin/env python
# encoding: utf-8
#
# Description: Hook for removing failed chronyd status when ntpd is ok
# Author: Pablo Iranzo Gomez (Pablo.Iranzo@gmail.com)

from __future__ import print_function

import os

try:
    import citellusclient.shell as citellus
except:
    import shell as citellus

# Load i18n settings from citellus
_ = citellus._

extension = "__file__"
pluginsdir = os.path.join(citellus.citellusdir, 'plugins', extension)


def init():
    """
    Initializes module
    :return: List of triggers for extension
    """
    return []


def run(data, quiet=False):  # do not edit this line
    """
    Executes plugin
    :param quiet: be more silent on returned information
    :param data: data to process
    :return: returncode, out, err
    """

    sourceid = citellus.getids(include=['/core/system/clock-1-ntpd.sh'])
    targetid = citellus.getids(include=['/core/system/clock-1-chrony.sh'])

    mangle = False

    # Grab source data
    for plugin in data:
        if plugin['id'] in sourceid:
            if plugin['result']['rc'] == citellus.RC_OKAY:
                mangle = True

    newdata = []
    for plugin in data:
        if plugin['id'] in targetid:
            if mangle:
                # We now fake result as SKIPPED and copy to datahook dict the new data
                plugin['datahook'] = {}
                plugin['datahook']['prior'] = dict(plugin['result'])
                plugin['result']['rc'] = citellus.RC_SKIPPED
                plugin['result']['err'] = 'Marked as skipped by data hook %s' % os.path.basename(__file__).split(os.sep)[0]
                citellus.LOG.debug("Data mangled for plugin %s:" % plugin['plugin'])
        newdata.append(plugin)

    return newdata


def help():  # do not edit this line
    """
    Returns help for plugin
    :return: help text
    """

    commandtext = _("This hook proceses Citellus outputs and unfails Chronyd if NTP is used")
    return commandtext
