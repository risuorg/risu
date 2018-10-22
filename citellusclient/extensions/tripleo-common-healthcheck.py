#!/usr/bin/env python
# encoding: utf-8
#
# Description: Extension for processing tripleo-common-healthcheck playbooks
# Author: Pablo Iranzo Gomez (Pablo.Iranzo@gmail.com)
# Copyright (C) 2018 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

from __future__ import print_function

import os

try:
    import citellusclient.shell as citellus
except:
    import shell as citellus

# Load i18n settings from citellus
_ = citellus._

extension = "tripleo-common-healthcheck"
pluginsdir = os.path.join(citellus.citellusdir, 'plugins', extension)


def init():
    """
    Initializes module
    :return: List of triggers for extension
    """
    triggers = ['tripleo-common-healthcheck']
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

    yield citellus.findplugins(folders=[pluginsdir], executables=True, extension='tripleo-common-healthcheck', prio=prio)


def get_metadata(plugin):
    """
    Gets metadata for plugin
    :param plugin: plugin object
    :return: metadata dict for that plugin
    """

    description = ""

    metadata = citellus.generic_get_metadata(plugin=plugin)
    metadata.update({'description': description, 'priority': 333})

    return metadata


def run(plugin):  # do not edit this line
    """
    Executes plugin
    :param plugin: plugin dictionary
    :return: returncode, out, err
    """

    if citellus.CITELLUS_LIVE == 1:
        # We're running in Live mode
        skipped = 0
    else:
        # We do not satisfy conditions, exit early
        skipped = 1

    if skipped == 1:
        return citellus.RC_SKIPPED, '', _('Plugin does not satisfy conditions for running')

    command = "sh %s " % plugin['plugin']

    # Call exec to run playbook
    returncode, out, err = citellus.execonshell(filename=command)

    # Do formatting of results to adjust return codes to citellus standards
    if returncode == 1:
        returncode = citellus.RC_FAILED
    elif returncode == 0:
        returncode = citellus.RC_OKAY

    # Convert stdout to stderr for citellus handling
    err = out
    out = ''

    return returncode, out, err


def help():  # do not edit this line
    """
    Returns help for plugin
    :return: help text
    """

    commandtext = _("This extension processes openstack-tripleo-common healthcheck scripts")
    return commandtext
