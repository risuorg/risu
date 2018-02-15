#!/usr/bin/env python
# encoding: utf-8
#
# Description: Hook for procesing profile definitions and appending results formated to json
# Author: Pablo Iranzo Gomez (Pablo.Iranzo@gmail.com)

from __future__ import print_function

import os

try:
    import citellusclient.shell as citellus
except:
    import shell as citellus

# Load i18n settings from citellus
_ = citellus._

extension = "profiles"
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

    # Find available profile definitions

    profiles = citellus.findplugins(folders=[pluginsdir], executables=False, fileextension='.txt')


    # By default it returns list, so get only one item
    sourceid = citellus.getids(include=['/core/system/clock-1-ntpd.sh'])[0]
    targetid = citellus.getids(include=['/core/system/clock-1-chrony.sh'])[0]

    mangle = False

    # Grab source data
    if sourceid in data:
        if data[sourceid]['result']['rc'] == citellus.RC_OKAY:
            mangle = True

    if mangle:
        # We now fake result as SKIPPED and copy to datahook dict the new data
        data[targetid]['datahook'] = {}
        data[targetid]['datahook']['prior'] = dict(data[targetid]['result'])
        data[targetid]['result']['rc'] = citellus.RC_SKIPPED
        data[targetid]['result']['err'] = 'Marked as skipped by data hook %s' % os.path.basename(__file__).split(os.sep)[0]
        citellus.LOG.debug("Data mangled for plugin %s:" % data[targetid]['plugin'])

    return data


def help():  # do not edit this line
    """
    Returns help for plugin
    :return: help text
    """

    commandtext = _("This hook proceses Citellus profiles and assembles data for each one to be appended to results json")
    return commandtext
