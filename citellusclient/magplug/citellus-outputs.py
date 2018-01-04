#!/usr/bin/env python
# encoding: utf-8
#
# Copyright (C) 2018  Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)
# Description: Plugin for reporting back citellus data from all sosreports

from __future__ import print_function

import os
import citellusclient.shell as citellus
import citellusclient.magui as magui

# Load i18n settings from citellus
_ = citellus._

extension = "citellus-outputs"
pluginsdir = os.path.join(citellus.citellusdir, 'plugins', extension)


def init():
    """
    Initializes module
    :return: List of triggers for Plugin
    """
    triggers = []
    return triggers


def run(data, quiet=False):  # do not edit this line
    """
    Executes plugin
    :param plugin: plugin dictionary
    :return: returncode, out, err
    """

    # Return all data passed from citellus

    # For now, let's only print plugins that have rc ! $RC_OKAY in quiet
    if quiet:
        toprint = magui.maguiformat(data)
    else:
        toprint = data

    return toprint


def help():  # do not edit this line
    """
    Returns help for plugin
    :return: help text
    """

    commandtext = _("This plugin checks Ceilometer pipeline.yaml consistency across sosreports")
    return commandtext
