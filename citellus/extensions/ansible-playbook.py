#!/usr/bin/env python
# encoding: utf-8
#
# Description: Extension for processing ansible playbooks
# Author: Pablo Iranzo Gomez (Pablo.Iranzo@gmail.com)

from __future__ import print_function

from citellus import findplugins, citellusdir, runplugin, docitellus

PlaybooksFolder = "playbooks"
import os


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
    triggers = []
    return triggers


def runplaybook(playbook):
    """
    Actually runs the playbook with Ansible
    :param playbook:
    """
    return


def run(options):  # do not edit this line
    """
    Executes plugin
    :param options: options passed to main binary
    :return:
    """

    if not which("ansible-playbook"):
        print("# skipping ansible per missing ansible-playbook")
        return

    print("We run it!!, yeeess we run it!")

    playbooksdir = os.path.join(citellusdir, PlaybooksFolder)
    plugins = findplugins(folders=[playbooksdir], include=options.include, exclude=options.exclude, executables=False)

    commands = []
    ansible=which("ansible-playbook")
    for each in plugins:
        commands.append("%s -i localhost, %s" % (ansible,each))


    print(commands)
    results=docitellus(live=True, path=None, plugins=commands, lang='en_US')

    print(results)

    return


def help():  # do not edit this line
    """
    Returns help for plugin
    :return: help text
    """

    commandtext = "This plugin proceses Ansible playbooks against the system"
    return commandtext
