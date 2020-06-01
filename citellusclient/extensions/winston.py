#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Description: Extension for processing file-based metadata generators in a similar way to what Faraday does
# Author: Pablo Iranzo Gomez (Pablo.Iranzo@gmail.com)
# Copyright (C) 2018, 2019, 2020 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>
#
# https://en.wikipedia.org/wiki/Winston_Smith

from __future__ import print_function

import os

try:
    import citellusclient.shell as citellus
except:
    import shell as citellus

# Load i18n settings from citellus
_ = citellus._

extension = "winston"
pluginsdir = os.path.join(citellus.citellusdir, "plugins", extension)


def init():
    """
    Initializes module
    :return: List of triggers for extension
    """
    triggers = ["winston"]
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
        executables=False,
        fileextension=".txt",
        extension=extension,
        prio=prio,
        options=options,
    )


def get_metadata(plugin):
    """
    Gets metadata for plugin
    :param plugin: plugin object
    :return: metadata dict for that plugin
    """

    return citellus.generic_get_metadata(plugin)


def run(plugin):  # do not edit this line
    """
    Executes plugin
    :return: returncode, out, err
    """
    filename = plugin["path"]

    skipped = 0
    if os.environ["CITELLUS_LIVE"] == 0 and citellus.regexpfile(
        filename=filename, regexp="CITELLUS_ROOT"
    ):
        # We're running in snapshoot and faraday file has CITELLUS_ROOT
        skipped = 0
    else:
        if os.environ["CITELLUS_LIVE"] == 1:
            if citellus.regexpfile(
                filename=plugin["plugin"], regexp="CITELLUS_HYBRID"
            ) or not citellus.regexpfile(filename=filename, regexp="CITELLUS_ROOT"):
                # We're running in Live mode and either plugin supports HYBRID or has no CITELLUS_ROOT
                skipped = 0
            else:
                # We do not satisfy conditions, exit early
                skipped = 1

    if skipped == 1:
        return (
            citellus.RC_SKIPPED,
            "",
            _("Plugin does not satisfy conditions for running"),
        )

    if "${CITELLUS_ROOT}" in filename:
        filename = filename.replace("${CITELLUS_ROOT}", os.environ["CITELLUS_ROOT"])

    if os.access(filename, os.R_OK):
        # We can read the file, so let's calculate md5sum
        out = ""
        err = open(filename, "rb").read()
        returncode = citellus.RC_OKAY
    else:
        returncode = citellus.RC_SKIPPED
        out = ""
        err = "File %s is not accessible in read mode" % filename

    return returncode, out, err


def help():  # do not edit this line
    """
    Returns help for plugin
    :return: help text
    """

    commandtext = _(
        "This extension creates fake plugins based on affinity/antiaffinity file list for later processing"
    )
    return commandtext
