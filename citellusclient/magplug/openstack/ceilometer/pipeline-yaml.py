#!/usr/bin/env python
# encoding: utf-8
#
# Copyright (C) 2018  Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)
# Description: Plugin for checking ceilimeter pipeline-yaml data

from __future__ import print_function

try:
    import citellusclient.shell as citellus
except:
    import shell as citellus

# Load i18n settings from citellus
_ = citellus._

extension = "pipeline-yaml"


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

    # Plugin ID to act on:
    plugid = "131c0e0d785fae9811f2754262f0da9e"

    ourdata = False
    for item in data:
        if data[item]['id'] == plugid:
            ourdata = data[item]

    if ourdata:
    

    return "PIIII"


def help():  # do not edit this line
    """
    Returns help for plugin
    :return: help text
    """

    commandtext = _("This plugin checks Ceilometer pipeline.yaml consistency across sosreports")
    return commandtext
