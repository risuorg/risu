#!/usr/bin/env python
# -*- coding: utf-8 -*-
# Description: Plugin for reporting back citellus data from all sosreports#

# Copyright (C) 2018 Robin Černín <cerninr@gmail.com>
# Copyright (C) 2018, 2019, 2020 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>


from __future__ import print_function

import os

import citellusclient.shell as citellus

# Load i18n settings from citellus
_ = citellus._

extension = "citellus-outputs"
pluginsdir = os.path.join(citellus.citellusdir, "plugins", extension)


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

    # Return all data passed from citellus
    toprint = data

    # We should filter metadata extension as is to be processed separately
    err = [
        toprint[item]
        for item in toprint
        if "backend" in toprint[item] and toprint[item]["backend"] != "metadata"
    ]

    # Do return different code if we've data
    if len(err) > 0:
        returncode = citellus.RC_FAILED
    else:
        returncode = citellus.RC_OKAY

    out = ""
    return returncode, out, err


def help():  # do not edit this line
    """
    Returns help for plugin
    :return: help text
    """

    commandtext = _("Plugin for reporting back citellus data from all sosreports")
    return commandtext
