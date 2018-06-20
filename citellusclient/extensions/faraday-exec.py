#!/usr/bin/env python
# encoding: utf-8
#
# Description: Extension for processing file affinities/antiaffinities to be reported in a
#              similar way to metadata and later processed by corresponding plugin in Magui
#
# Author: Pablo Iranzo Gomez (Pablo.Iranzo@gmail.com)
# Copyright (C) 2018 Robin Černín <cerninr@gmail.com>
# Copyright (C) 2018 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

from __future__ import print_function

import os

try:
    import citellusclient.shell as citellus
except:
    import shell as citellus

# Load i18n settings from citellus
_ = citellus._

extension = "faraday-exec"
# We look for plugins in standard faraday path
pluginsdir = os.path.join(citellus.citellusdir, 'plugins', 'faraday')


def init():
    """
    Initializes module
    :return: List of triggers for extension
    """
    triggers = ['faraday-exec']
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

    plugins = citellus.findplugins(folders=[pluginsdir], fileextension=".sh", extension=extension, prio=prio)

    yield plugins


def get_metadata(plugin):
    """
    Gets metadata for plugin
    :param plugin: plugin object
    :return: metadata dict for that plugin
    """

    metadata = citellus.generic_get_metadata(plugin=plugin)

    subcategory = os.path.split(plugin['plugin'])[0].replace(pluginsdir, '')
    category = os.path.normpath(subcategory).split(os.sep)[1] or ''
    metadata.update({'subcategory': subcategory, 'category': category})

    return metadata


def run(plugin):  # do not edit this line
    """
    Executes plugin
    :return: returncode, out, err
    """

    return citellus.execonshell(filename=plugin['plugin'])


def help():  # do not edit this line
    """
    Returns help for plugin
    :return: help text
    """

    commandtext = _("This extension creates fake plugins based on affinity/antiaffinity file list for later processing")
    return commandtext
