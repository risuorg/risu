#!/usr/bin/env python
# encoding: utf-8
#
# Copyright (C) 2018  Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)
# Description: Plugin for checking galera/mysql sequence number across servers

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
    plugid = "2c09ace9f807fe2fc4e896bd7819ff72"

    ourdata = False
    for item in data:
        if data[item]['id'] == plugid:
            ourdata = data[item]

    message = []

    if ourdata:
        # 'err' in this case is something like: 08a94e67-bae0-11e6-8239-9a6188749d23:36117633
        # being UUID: seqno
        err = []
        for sosreport in ourdata['sosreport']:
            err.append(ourdata['sosreport'][sosreport]['err'])

        if len(sorted(set(err))) != 1:
            message = _("Galera sequence nmber differ across sosreports")

        # Find max in values
        max = 0
        for each in err:
            try:
                seqno = each.split(':')[1]
            except:
                seqno = 0
            if seqno > max:
                max = seqno

        host = False
        for sosreport in ourdata['sosreport']:
            if seqno in ourdata['sosreport'][sosreport]['err']:
                host = sosreport

        if host:
            message = _("Host %s contains highest sequence in Galera consider that one for bootstraping if needed." % host)

        # find max in sosreport to report host

    return message


def help():  # do not edit this line
    """
    Returns help for plugin
    :return: help text
    """

    commandtext = _("This plugin checks Galera sequence number across sosreports")
    return commandtext
