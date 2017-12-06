#!/usr/bin/env python
# encoding: utf-8
#
# Description: Extension for processing classic Citellus plugins
# Author: Pablo Iranzo Gomez (Pablo.Iranzo@gmail.com)

from __future__ import print_function

import os

try:
    # Python 3
    from .. import citellus
except ValueError:
    # Python 2
    import citellus

PlaybooksFolder = "core"


def which(binary):
    """
    Locates where a binary is located within path
    :param binary: Binary to locate/executable
    :return: path or None if not found
    """

    def is_executable(file):
        return os.path.isfile(file) and os.access(file, os.X_OK)

    path, file = os.path.split(binary)
    if path:
        if is_executable(binary):
            return binary
    else:
        for path in os.environ["PATH"].split(os.pathsep):
            executable = os.path.join(path, binary)
            if is_executable(executable):
                return executable

    return None


def init():
    """
    Initializes module
    :return: List of triggers for plugin
    """
    triggers = ['core']
    return triggers


def list(options):
    playbooksdir = os.path.join(citellus.citellusdir, 'plugins', PlaybooksFolder)
    playbooks = citellus.findplugins(folders=[playbooksdir], include=options.include, exclude=options.exclude,
                                     executables=False, extension=".yml")
    return playbooks


def run(options):  # do not edit this line
    """
    Executes plugin
    :param options: options passed to main binary
    :return:
    """

    if not which("ansible-playbook"):
        print("# skipping ansible per missing ansible-playbook binary.")
        return

    playbooksdir = os.path.join(citellus.citellusdir, PlaybooksFolder)
    playbooks = citellus.findplugins(folders=[playbooksdir], include=options.include, exclude=options.exclude,
                                     executables=False, extension=".yml")
    playbooklive = []
    playbooksnap = []

    for playbook in playbooks:
        if citellus.regexpfile(file=playbook, regexp="CITELLUS_ROOT"):
            playbooksnap.append(playbook)
        else:
            playbooklive.append(playbook)

    # Restrict the playbooks to process to the running mode
    if options.live is True:
        playbooks = playbooklive
        playbookskipped = playbooksnap
    else:
        playbooks = playbooksnap
        playbookskipped = playbooklive

    # There are plugins that can be run in Live and Snapshot mode (Find string CITELLUS_HYBRID), by default the Hybrid
    # ones will be flagged as snapshot mode, so we only process them in case we're running live.

    if options.live is True:
        for playbook in playbooksnap:
            if citellus.regexpfile(file=playbook, regexp="CITELLUS_HYBRID"):
                # Add to the list of playbooks to run
                playbooks.append(playbook)

                # Remove from the skipped playbooks
                playbookskipped.remove(playbook)

    commands = []
    ansible = which("ansible-playbook")
    for playbook in playbooks:
        commands.append("%s -i localhost --connection=local, %s" % (ansible, playbook))

    # Actually run the tests
    results = citellus.docitellus(live=options.live, path=None, plugins=commands, lang='en_US')

    # Do formatting of results to remove ansible-playbook -i localhost, and adjust return codes to citellus standards
    for result in results:
        # Convert RC codes to what citellus expects
        if result['result']['rc'] == 2:
            result['result']['rc'] = citellus.RC_FAILED
        elif result['result']['rc'] == 0:
            result['result']['rc'] = citellus.RC_OKAY

        # Convert stdout to stderr for citellus handling
        result['result']['err'] = result['result']['out']
        result['result']['out'] = ''

        # Remove ansible-playbook command and just leave yml file
        result['plugin'] = result['plugin'].replace(which('ansible-playbook'), '').replace(' -i localhost --connection=local, ', '')

    # Now, fake 'skipped' for all the plugins which were tied to the mode we're not running in:
    for playbook in playbookskipped:
        dictionary = {'plugin': playbook,
                      'result': {'rc': citellus.RC_SKIPPED, 'err': 'Skipped for incompatible operating mode', 'out': ''}}
        results.append(dictionary)

    return results


def help():  # do not edit this line
    """
    Returns help for plugin
    :return: help text
    """

    commandtext = "This plugin proceses Ansible playbooks against the system"
    return commandtext
