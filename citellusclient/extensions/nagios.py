#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Description: Extension for processing nagios Citellus plugins
# Author: Pablo Iranzo Gomez (Pablo.Iranzo@gmail.com)
# Copyright (C) 2021 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

from __future__ import print_function

import os


try:
    import citellusclient.shell as citellus
except:
    import shell as citellus

# Load i18n settings from citellus
_ = citellus._

extension = "nagios"
pluginsdir = os.path.join(citellus.citellusdir, "plugins", extension)


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

    yield citellus.findplugins(
        folders=folders, prio=prio, options=options, extension="nagios"
    )


def get_metadata(plugin):
    """
    Gets metadata for plugin
    :param plugin: plugin object
    :return: metadata dict for that plugin
    """

    metadata = citellus.generic_get_metadata(plugin=plugin)
    metadata["backend"] = "nagios"
    return metadata


def run(plugin):  # do not edit this line
    """
    Executes plugin
    :return: returncode, out, err
    """
    # Call exec to run playbook
    returncode, out, err = citellus.execonshell(filename=plugin["plugin"])

    # Do formatting of results to adjust return codes to citellus standards
    if returncode == 2:
        returncode = citellus.RC_FAILED
    elif returncode == 0:
        returncode = citellus.RC_OKAY
    elif returncode == 1:
        returncode = citellus.RC_INFO

    # Convert stdout to stderr for citellus handling
    err = out
    out = ""

    return returncode, out, err


def help():  # do not edit this line
    """
    Returns help for plugin
    :return: help text
    """

    commandtext = _("This extension proceses Citellus nagios plugins")
    return commandtext
