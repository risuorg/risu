#!/usr/bin/env python
# encoding: utf-8
#
# Description: Hook for removing unknwon process status (-9) because of execution timeout
# Copyright (C) 2018 Pablo Iranzo Gomez (Pablo.Iranzo@redhat.com)

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
    skipped = int(os.environ['RC_SKIPPED'])

    for plugin in data:
        if data[plugin]['result']['rc'] == -9:
            # We now fake result as SKIPPED and copy to datahook dict the new data
            data[plugin]['datahook'] = {}
            data[plugin]['datahook']['prior'] = dict(data[plugin]['result'])
            newresults = dict(data[plugin]['result'])
            newresults['rc'] = skipped
            newresults['err'] = 'Marked as skipped by data hook %s' % os.path.basename(__file__).split(os.sep)[0]
            data[plugin]['result'] = newresults
            citellus.LOG.debug("Data mangled for plugin %s:" % data[plugin]['plugin'])

    return data


def help():  # do not edit this line
    """
    Returns help for plugin
    :return: help text
    """

    commandtext = _("This hook proceses Citellus outputs and skips plugins that timedout during execution")
    return commandtext
