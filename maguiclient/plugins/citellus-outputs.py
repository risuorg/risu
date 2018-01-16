#!/usr/bin/env python
# encoding: utf-8
#
# Copyright (C) 2018  Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)
# Description: Plugin for reporting back citellus data from all sosreports

from __future__ import print_function

import os

import citellusclient.shell as citellus
import maguiclient.magui as magui

# Load i18n settings from citellus
_ = citellus._

extension = "citellus-outputs"
pluginsdir = os.path.join(citellus.citellusdir, 'plugins', extension)


def init():
    """
    Initializes module
    :return: List of triggers for Plugin
    """
    triggers = ['*']
    return triggers


def run(data, quiet=False):  # do not edit this line
    """
    Executes plugin
    :param data: data to process
    :param quiet: work in reduced noise mode
    :return: returncode, out, err
    """

    # Return all data passed from citellus

    # For now, let's only print plugins that have rc ! $RC_OKAY in quiet
    if quiet:
        toprint = magui.maguiformat(data)
    else:
        toprint = data

    # We should filter metadata extension as is to be processed separately
    err = []
    for item in toprint:
        if toprint[item]['backend'] != 'metadata':
            err.append(toprint[item])

    # Do return different code if we've data
    if len(err) > 0:
        returncode = citellus.RC_FAILED
    else:
        returncode = citellus.RC_OKAY

    out = ''
    return returncode, out, err


def help():  # do not edit this line
    """
    Returns help for plugin
    :return: help text
    """

    commandtext = _("Plugin for reporting back citellus data from all sosreports")
    return commandtext
