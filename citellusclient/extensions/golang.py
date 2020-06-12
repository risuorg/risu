#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Description: Extension for processing GOlang Citellus plugins
# Author: Pablo Iranzo Gomez (Pablo.Iranzo@gmail.com)
# Copyright (C) 2020 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

from __future__ import print_function

import os

try:
    import citellusclient.shell as citellus
except:
    import shell as citellus

# Load i18n settings from citellus
_ = citellus._

extension = "golang"
pluginsdir = os.path.join(citellus.citellusdir, "plugins", extension)


def init():
    """
    Initializes module
    :return: List of triggers for extension
    """
    triggers = ["golang"]
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
        folders=folders,
        prio=prio,
        options=options,
        executables=False,
        fileextension=".go",
        extension="golang",
    )


def get_metadata(plugin):
    """
    Gets metadata for plugin
    :param plugin: plugin object
    :return: metadata dict for that plugin
    """

    return citellus.generic_get_metadata(plugin=plugin, comment="//")


def run(plugin):  # do not edit this line
    """
    Executes plugin
    :param plugin: plugin dictionary
    :return: returncode, out, err
    """

    gorun = citellus.which("go")
    if not gorun:
        return citellus.RC_SKIPPED, "", _("Golang support not found")

    filename = plugin["plugin"]

    # Call exec to run playbook

    mypath = os.getcwd()

    path = os.path.dirname(filename)
    file = os.path.basename(filename)

    # Compiling
    binary = os.path.splitext(filename)[0]

    os.chdir(path)
    try:
        os.remove(binary)
    except:
        pass
    command = "%s build %s" % (gorun, file)

    citellus.execonshell(filename=command)

    # Go back to our folder
    os.chdir(mypath)

    # Running
    returncode, out, err = citellus.execonshell(filename=binary)

    return returncode, out, err


def help():  # do not edit this line
    """
    Returns help for plugin
    :return: help text
    """

    commandtext = _("This extension proceses Citellus golang plugins")
    return commandtext
