#!/usr/bin/env python
# encoding: utf-8
#
# Description: Hook for moving faraday-exec results into regular faraday
# Author: Pablo Iranzo Gomez (Pablo.Iranzo@gmail.com)

from __future__ import print_function

import os

try:
    import citellusclient.shell as citellus
except:
    import shell as citellus

# Load i18n settings from citellus
_ = citellus._

extension = "__file__"
pluginsdir = os.path.join(citellus.citellusdir, 'plugins', extension)


def init():
    """
    Initializes module
    :return: List of triggers for extension
    """
    return []


def run(data, quiet=False):  # do not edit this line
    """
    Executes plugin
    :param quiet: be more silent on returned information
    :param data: data to process
    :return: returncode, out, err
    """

    # Act on all faraday-exec plugins
    for pluginid in data:
        if data[pluginid]['backend'] == 'faraday-exec':
            data[pluginid]['backend'] = 'faraday'

    return data


def help():  # do not edit this line
    """
    Returns help for plugin
    :return: help text
    """

    commandtext = _("This hook proceses faraday-exec results and converts to faraday for Magui plugin to work")
    return commandtext
