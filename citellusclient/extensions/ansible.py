#!/usr/bin/env python
# encoding: utf-8
#
# Description: Extension for processing ansible playbooks
# Author: Pablo Iranzo Gomez (Pablo.Iranzo@gmail.com)

from __future__ import print_function

import os

try:
    import yaml
except:
    pass

try:
    import citellusclient.shell as citellus
except:
    import shell as citellus

# Load i18n settings from citellus
_ = citellus._

extension = "ansible"
pluginsdir = os.path.join(citellus.citellusdir, 'plugins', extension)


def init():
    """
    Initializes module
    :return: List of triggers for extension
    """
    triggers = ['ansible']
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

    yield citellus.findplugins(folders=[pluginsdir], executables=False, fileextension=".yml", extension='ansible', prio=prio)


def get_metadata(plugin):
    """
    Gets meadata for plugin
    :param plugin: plugin object
    :return: metadata dict for that plugin
    """

    with open(plugin['plugin'], 'r') as stream:
        try:
            doc = (yaml.load(stream))
        except:
            doc = ""

    try:
        description = doc[0]['vars']['metadata']['description']
    except:
        description = ""

    metadata = {'description': description,
                'long_name': citellus.regexpfile(filename=plugin['plugin'], regexp='\A# long_name:')[12:].strip(),
                'bugzilla': citellus.regexpfile(filename=plugin['plugin'], regexp='\A# bugzilla:')[11:].strip(),
                'priority': int(citellus.regexpfile(filename=plugin['plugin'], regexp='\A# priority:')[11:].strip() or 0)}

    return metadata


def run(plugin):  # do not edit this line
    """
    Executes plugin
    :param plugin: plugin dictionary
    :return: returncode, out, err
    """

    ansible = citellus.which("ansible-playbook")
    if not ansible:
        return citellus.RC_SKIPPED, '', _('ansible-playbook support not found')

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
        return citellus.RC_SKIPPED, '', _('Plugin does not satisfy conditions for running')

    command = "%s -i localhost, --connection=local %s" % (ansible, plugin['plugin'])

    # Disable Ansible retry files creation:
    os.environ['ANSIBLE_RETRY_FILES_ENABLED'] = "0"

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

    # Rewrite error messages to not contain all playbook execution but just the actual error
    if 'FAILED!' in err:
        start = err.find('FAILED!', 0) + 11
        end = err.find('PLAY RECAP', 0) - 10
        newtext = err[start:end]
        err = newtext

    return returncode, out, err


def help():  # do not edit this line
    """
    Returns help for plugin
    :return: help text
    """

    commandtext = _("This extension processes Ansible playbooks")
    return commandtext
