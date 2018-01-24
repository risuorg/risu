#!/usr/bin/env python
# encoding: utf-8
#
# Description: Extension for processing file affinities/antiaffinities to be reported in a 
#              similar way to metadata and later processed by corresponding plugin in Magui
# 
# Author: Pablo Iranzo Gomez (Pablo.Iranzo@gmail.com)

from __future__ import print_function

import os

try:
    import citellusclient.shell as citellus
except:
    import shell as citellus

# Load i18n settings from citellus
_ = citellus._

extension = "faraday"
pluginsdir = os.path.join(citellus.citellusdir, 'plugins', extension)


def init():
    """
    Initializes module
    :return: List of triggers for extension
    """
    triggers = ['faraday']
    return triggers


def listplugins(options):
    """
    List available plugins
    :param options: argparse options provided
    :return: plugin object generator
    """

    yield citellus.findplugins(folders=[pluginsdir], executables=False, fileextension=".txt", extension=extension, prio=options.prio)


def get_metadata(plugin):
    """
    Gets metadata for plugin
    :param plugin: plugin object
    :return: metadata dict for that plugin
    """

    metadata = {'description': citellus.regexpfile(filename=plugin['plugin'], regexp='\A# description:')[14:].strip(),
                'long_name': citellus.regexpfile(filename=plugin['plugin'], regexp='\A# long_name:')[12:].strip(),
                'bugzilla': citellus.regexpfile(filename=plugin['plugin'], regexp='\A# bugzilla:')[11:].strip(),
                'priority': int(citellus.regexpfile(filename=plugin['plugin'], regexp='\A# priority:')[11:].strip() or 0)}
    return metadata


def run(plugin):  # do not edit this line
    """
    Executes plugin
    :return: returncode, out, err
    """

    # TODO: return md5sum of passed file (ideally within python) and RC_SKIPPED when not for current operation mode
    return citellus.execonshell(filename=plugin['plugin'])


def help():  # do not edit this line
    """
    Returns help for plugin
    :return: help text
    """

    commandtext = _("This extension creates fake plugins based on affinity/antiaffinity file list for later processing")
    return commandtext
