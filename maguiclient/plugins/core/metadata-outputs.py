#!/usr/bin/env python
# -*- coding: utf-8 -*-
# Description: Plugin for reporting back risu metadata from all sosreports

# Copyright (C) 2018, 2019, 2020, 2021 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>


from __future__ import print_function

import os

import maguiclient.magui as magui
import risuclient.shell as risu

# Load i18n settings from risu
_ = risu._

extension = "metadata-outputs"
pluginsdir = os.path.join(risu.risudir, "plugins", extension)


def init():
    """
    Initializes module
    :return: List of triggers for Plugin
    """
    triggers = ["*"]
    return triggers


def run(data, quiet=False):  # do not edit this line
    """
    Executes plugin
    :param data: data to process
    :param quiet: work in reduced noise mode
    :return: returncode, out, err
    """

    # Return all metadata passed from risu

    # For now, let's only print plugins that have rc ! $RC_OKAY in quiet
    if quiet:
        toprint = magui.maguiformat(data)
    else:
        toprint = data

    # We should filter metadata extension as is to be processed separately
    err = [
        toprint[item]
        for item in toprint
        if "backend" in toprint[item] and toprint[item]["backend"] == "metadata"
    ]

    # Do return different code if we've data
    if len(err) > 0:
        returncode = risu.RC_FAILED
    else:
        returncode = risu.RC_OKAY

    out = ""
    return returncode, out, err


def help():  # do not edit this line
    """
    Returns help for plugin
    :return: help text
    """

    commandtext = _("Plugin for reporting back risu metadata from all sosreports")
    return commandtext
