#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Description: Extension for processing core Citellus plugins
# Author: Pablo Iranzo Gomez (Pablo.Iranzo@gmail.com)
# Copyright (C) 2017, 2018, 2019, 2020 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

from __future__ import print_function

import os

try:
    import citellusclient.shell as citellus
except:
    import shell as citellus

# Load i18n settings from citellus
_ = citellus._

extension = "core"
pluginsdir = os.path.join(citellus.citellusdir, "plugins", extension)


def init():
    """
    Initializes module
    :return: List of triggers for extension
    """
    triggers = ["core"]
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

    yield citellus.findplugins(folders=folders, prio=prio, options=options)


def get_metadata(plugin):
    """
    Gets metadata for plugin
    :param plugin: plugin object
    :return: metadata dict for that plugin
    """

    return citellus.generic_get_metadata(plugin=plugin)


def run(plugin):  # do not edit this line
    """
    Executes plugin
    :return: returncode, out, err
    """
    return citellus.execonshell(filename=plugin["plugin"])


def help():  # do not edit this line
    """
    Returns help for plugin
    :return: help text
    """

    commandtext = _("This extension proceses Citellus core plugins")
    return commandtext
