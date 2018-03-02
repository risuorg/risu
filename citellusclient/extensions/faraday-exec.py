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

    plugins = citellus.findplugins(folders=[pluginsdir], executables=True, fileextension=".sh", extension=extension, prio=prio)

    yield plugins


def get_metadata(plugin):
    """
    Gets metadata for plugin
    :param plugin: plugin object
    :return: metadata dict for that plugin
    """

    path = citellus.regexpfile(filename=plugin['plugin'], regexp='\A# path:')[7:].strip()
    citellus.LOG.debug('IRANZO')
    citellus.LOG.debug(path)
    path = path.replace('${CITELLUS_ROOT}', '')
    citellus.LOG.debug(path)

    metadata = {'description': citellus.regexpfile(filename=plugin['plugin'], regexp='\A# description:')[14:].strip(),
                'long_name': citellus.regexpfile(filename=plugin['plugin'], regexp='\A# long_name:')[12:].strip(),
                'bugzilla': citellus.regexpfile(filename=plugin['plugin'], regexp='\A# bugzilla:')[11:].strip(),
                'priority': int(citellus.regexpfile(filename=plugin['plugin'], regexp='\A# priority:')[11:].strip() or 0),
                'path': path}
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
