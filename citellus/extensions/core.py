#!/usr/bin/env python
# encoding: utf-8
#
# Description: Extension for processing core Citellus plugins
# Author: Pablo Iranzo Gomez (Pablo.Iranzo@gmail.com)

from __future__ import print_function

import os

try:
    # Python 3
    from .. import citellus
except ValueError:
    # Python 2
    import citellus

PlaybooksFolder = "core"


def init():
    """
    Initializes module
    :return: List of triggers for plugin
    """
    triggers = ['core']
    return triggers


def list(options):
    playbooksdir = os.path.join(citellus.citellusdir, 'plugins', PlaybooksFolder)
    playbooks = citellus.findplugins(folders=[playbooksdir], include=options.include, exclude=options.exclude,
                                     executables=True, extension='core')
    return playbooks


def run(options):  # do not edit this line
    """
    Executes plugin
    :param options: options passed to main binary
    :return:
    """

    playbooksdir = os.path.join(citellus.citellusdir, 'plugins', PlaybooksFolder)
    commands = citellus.findplugins(folders=[playbooksdir], include=options.include, exclude=options.exclude,
                                     executables=True, extension='core')
   
    # Actually run the tests
    results = citellus.docitellus(live=options.live, path=None, plugins=commands, lang='en_US')
   
    return results


def help():  # do not edit this line
    """
    Returns help for plugin
    :return: help text
    """

    commandtext = "This extension proceses Citellus core plugins"
    return commandtext
