#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Description: Extension for processing rhv-log-collector-analizer
# Author: Pablo Iranzo Gomez (Pablo.Iranzo@gmail.com)
# Copyright (C) 2018, 2019, 2020, 2021 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>


from __future__ import print_function

import os

try:
    import yaml
except:
    pass

try:
    import risuclient.shell as risu
except:
    import shell as risu

# Load i18n settings from risu
_ = risu._

extension = "rhv-log-collector-analyzer"
pluginsdir = os.path.join(risu.risudir, "plugins", extension)


def init():
    """
    Initializes module
    :return: List of triggers for extension
    """
    triggers = ["rhv-log-collector-analyzer"]
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
        folders=folders,
        executables=False,
        fileextension=".txt",
        extension="rhv-log-collector-analyzer",
        prio=prio,
        options=options,
    )


def get_metadata(plugin):
    """
    Gets meadata for plugin
    :param plugin: plugin object
    :return: metadata dict for that plugin
    """

    with open(plugin["plugin"], "r") as stream:
        try:
            doc = yaml.safe_load(stream)
        except:
            doc = ""

    try:
        description = doc[0]["vars"]["metadata"]["description"]
    except:
        description = ""

    metadata = risu.generic_get_metadata(plugin=plugin)
    metadata.update({"description": description})

    return metadata


def run(plugin):  # do not edit this line
    """
    Executes plugin
    :param plugin: plugin dictionary
    :return: returncode, out, err
    """

    rhvlc = risu.which("rhv-log-collector-analyzer-live")
    # rhv-log-collector-analyzer-live --json
    if not rhvlc:
        return (
            risu.RC_SKIPPED,
            "",
            _("rhv-log-collector-analyzer-live support not found"),
        )

    if risu.RISU_LIVE == 0:
        # We're running in snapshoot
        skipped = 1
    elif risu.RISU_LIVE == 1:
        # We're running in Live mode
        skipped = 0
    else:
        # We do not satisfy conditions, exit early
        skipped = 1

    if skipped == 1:
        return (
            risu.RC_SKIPPED,
            "",
            _("Plugin does not satisfy conditions for running"),
        )

    command = "%s --json" % rhvlc

    # Call exec to run playbook
    returncode, out, err = risu.execonshell(filename=command)

    # Do formatting of results and adjust return codes to risu standards
    if returncode == 2:
        returncode = risu.RC_FAILED
    elif returncode == 0:
        returncode = risu.RC_OKAY

    # Convert stdout to stderr for risu handling
    try:
        err = out
    except:
        err = "Failed to convert output from log-analyzer"
        returncode = risu.RC_SKIPPED

    out = ""

    return returncode, out, err


def help():  # do not edit this line
    """
    Returns help for plugin
    :return: help text
    """

    commandtext = _("This extension processes rhv-log-collector-analyzer output")
    return commandtext
