#!/usr/bin/env python
# encoding: utf-8
#
# Description: Extension for processing ansible playbooks
# Author: Pablo Iranzo Gomez (Pablo.Iranzo@gmail.com)

from __future__ import print_function

import os

try:
    # Python 3
    from .. import citellus
except ValueError:
    # Python 2
    import citellus

extension = "ansible"
pluginsdir = os.path.join(citellus.citellusdir, 'plugins', extension)


def init():
    """
    Initializes module
    :return: List of triggers for extension
    """
    triggers = ['ansible']
    return triggers


def listplugins(options):
    """
    List available plugins
    :param options: argparse options provided
    :return: plugin object generator
    """
    yield citellus.findplugins(folders=[pluginsdir], include=options.include, exclude=options.exclude,
                               executables=False, fileextension=".yml", extension='ansible')


def get_description(plugin):
    """
    Gets description for plugin
    :param plugin: plugin object
    :return: description string for that plugin
    """
    return ""


def run(plugin):  # do not edit this line
    """
    Executes plugin
    :param plugin: plugin dictionary
    :return: returncode, out, err
    """

    ansible = citellus.which("ansible-playbook")
    if not ansible:
        return citellus.RC_SKIPPED, '', 'ansible-playbook support not found'

    if citellus.CITELLUS_LIVE == 0 and citellus.regexpfile(filename=plugin['plugin'], regexp="CITELLUS_ROOT"):
        # We're running in snapshoot and playbook has CITELLUS_ROOT
        skipped = 0
    elif citellus.CITELLUS_LIVE == 1:
        if citellus.regexpfile(filename=plugin['plugin'], regexp="CITELLUS_HYBRID") or not citellus.regexpfile(filename=plugin['plugin'], regexp="CITELLUS_ROOT"):
            # We're running in Live mode and either plugin supports HYBRID or has no CITELLUS_ROOT
            skipped = 0
        else:
            # We do not satisfy conditions, exit early
            skipped = 1
    else:
            # We do not satisfy conditions, exit early
            skipped = 1

    if skipped == 1:
        return citellus.RC_SKIPPED, '', 'Plugin does satisfies conditions for running'

    command = "%s -i localhost --connection=local, %s" % (ansible, plugin['plugin'])

    # Call exec to run playbook
    returncode, out, err = citellus.execonshell(filename=command)

    # Do formatting of results to remove ansible-playbook -i localhost, and adjust return codes to citellus standards
    if returncode == 2:
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

    commandtext = "This extension proceses Ansible playbooks"
    return commandtext
