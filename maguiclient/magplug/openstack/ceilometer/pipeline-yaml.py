#!/usr/bin/env python
# encoding: utf-8
#
# Copyright (C) 2018  Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)
# Description: Plugin for checking Ceilometer pipeline-yaml data

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
    triggers = ['131c0e0d785fae9811f2754262f0da9e']
    return triggers


def run(data, quiet=False):  # do not edit this line
    """
    Executes plugin
    :param quiet: reduce amount of data returned
    :param data: data to process
    :return: returncode, out, err
    """

    # Plugin ID to act on:
    plugid = "131c0e0d785fae9811f2754262f0da9e"
    returncode = citellus.RC_OKAY

    ourdata = False
    for item in data:
        if data[item]['id'] == plugid:
            ourdata = data[item]

    message = []

    if ourdata:
        # 'err' in this case should be always equal to the md5sum of the file so that we can report the problem
        err = []
        for sosreport in ourdata['sosreport']:
            err.append(ourdata['sosreport'][sosreport]['err'])

        if len(sorted(set(err))) != 1:
            message = _("Pipeline.yaml contents differ across sosreports, please do check that the contents are the same and shared across the environment to ensure proper behavior.")
            returncode = citellus.RC_FAILED

    out = ''
    err = message
    return returncode, out, err


def help():  # do not edit this line
    """
    Returns help for plugin
    :return: help text
    """

    commandtext = _("This plugin checks Ceilometer pipeline.yaml consistency across sosreports")
    return commandtext
