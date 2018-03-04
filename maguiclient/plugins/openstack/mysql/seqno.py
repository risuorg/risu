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
    ids = citellus.getids(include=['/core/openstack/mysql/seqno.sh'])
    return ids


def run(data, quiet=False):  # do not edit this line
    """
    Executes plugin
    :param quiet: be more silent on returned information
    :param data: data to process
    :return: returncode, out, err
    """

    returncode = citellus.RC_OKAY

    message = ''
    for ourdata in data:
        # 'err' in this case is something like: 08a94e67-bae0-11e6-8239-9a6188749d23:36117633
        # being UUID: seqno
        err = []
        for sosreport in data[ourdata]['sosreport']:
            err.append(data[ourdata]['sosreport'][sosreport]['err'])

        if len(sorted(set(err))) != 1:
            message = _("Galera sequence number differ across sosreports")

        # Find max in values
        maximum = 0
        for each in err:
            try:
                seqno = int(each.split(':')[1])
            except:
                seqno = 0
            if seqno > maximum:
                maximum = seqno

        host = False
        for sosreport in data[ourdata]['sosreport']:
            if data[ourdata]['sosreport'][sosreport]['rc'] == citellus.RC_OKAY:
                if data[ourdata]['sosreport'][sosreport]['err'].find("%s" % seqno):
                    host = sosreport
            else:
                message = _('Some of the sosreports failed to grab required data, skipping')
                returncode = citellus.RC_SKIPPED

        if host:
            message = _("Host %s contains highest sequence in Galera consider that one for bootstraping if needed." % host)
            returncode = citellus.RC_FAILED

        # find max in sosreport to report host
    out = ''
    err = message
    return returncode, out, err


def help():  # do not edit this line
    """
    Returns help for plugin
    :return: help text
    """

    commandtext = _("This plugin checks Galera sequence number across sosreports")
    return commandtext
