#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Description: Extension for processing nagios Risu plugins
# Author: Pablo Iranzo Gomez (Pablo.Iranzo@gmail.com)
# Copyright (C) 2021 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

from __future__ import print_function

import os

try:
    import risuclient.shell as risu
except:
    import shell as risu

# Load i18n settings from risu
_ = risu._

extension = "nagios"
pluginsdir = os.path.join(risu.risudir, "plugins", extension)


def init():
    """
    Initializes module
    :return: List of triggers for extension
    """
    triggers = ["nagios"]
    return triggers


def listplugins(options=None):
    """
    List available plugins
    :param options: argparse options provided
    :return: plugin object generator
    """

    prio = 0
    if options:
        try:
            prio = options.prio
        except:
            pass

    if options and options.extraplugintree:
        folders = [pluginsdir, os.path.join(options.extraplugintree, extension)]
    else:
        folders = [pluginsdir]

    yield risu.findplugins(
        folders=folders, prio=prio, options=options, extension="nagios"
    )


def get_metadata(plugin):
    """
    Gets metadata for plugin
    :param plugin: plugin object
    :return: metadata dict for that plugin
    """

    metadata = risu.generic_get_metadata(plugin=plugin)
    metadata["backend"] = "nagios"
    return metadata


def run(plugin):  # do not edit this line
    """
    Executes plugin
    :return: returncode, out, err
    """
    # Call exec to run playbook
    returncode, out, err = risu.execonshell(filename=plugin["plugin"])

    # Do formatting of results to adjust return codes to risu standards
    if returncode == 2:  # CRITICAL
        returncode = risu.RC_FAILED
    elif returncode == 0:  # OK
        returncode = risu.RC_OKAY
    elif returncode == 1:  # WARNING
        returncode = risu.RC_INFO
    elif returncode == 3:  # UNKNOWN
        returncode = risu.RC_SKIPPED

    # Convert stdout to stderr for risu handling
    err = out
    out = ""

    return returncode, out, err


def help():  # do not edit this line
    """
    Returns help for plugin
    :return: help text
    """

    commandtext = _("This extension proceses Risu nagios plugins")
    return commandtext
