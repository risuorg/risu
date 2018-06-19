#!/usr/bin/env python
# encoding: utf-8
#
# Description: Hook for moving rhv-log-collector-analyzer results to individual tests results
# Copyright (C) 2018 Pablo Iranzo Gómez <Pablo.Iranzo@redhat.com>

from __future__ import print_function

import os
import json

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
    idstodel = []
    datatoadd = []

    rhvlcid = citellus.calcid(string='/plugins/rhv-log-collector-analyzer/virtualization/base.txt')
    # Loop over plugin id's in data
    for pluginid in data:
        if data[pluginid]['id'] == rhvlcid:
            # Make a copy of dict for working on it
            plugin = dict(data[pluginid])['result']['err']

            # Fake data until we've the way to run it
            plugin = json.load(open('/home/iranzo/DEVEL/citellus/citellus/logcollector2.json','r'))['rhv-log-collector-live']

            # Add plugin ID to be removed for resulting data
            idstodel.append(str(pluginid))

            # Iterate over plugindata items
            for item in plugin:
                # Item ID in log-collector is not unique
                newid = item['id']

                if 'WARNING' in item['message_type']:
                    returncode = citellus.RC_FAILED
                else:
                    returncode = citellus.RC_OKAY

                # Write plugin entry for the individual result
                newitem = {newid: {'name': item['label'],
                        'description': item['message'],
                        'long_name':item['label'],
                        'id': newid,
                        'category':'',
                        'priority':400,
                        'bugzilla':'',
                        'time':0,
                        'subcategory':'',
                        'hash':item['filemd5'],
                        'result': {'out': '', 'err': "%s" % item['result'], 'rc': returncode},
                        'plugin': item['filepath'],
                        'backend': 'rhv-log-collector-analizer',
                        'kb':''}}

                datatoadd.append(newitem)

    # Process id's to remove
    for id in idstodel:
        del data[id]

    # Process data to add
    for item in datatoadd:
        data.update(item)

    return data


def help():  # do not edit this line
    """
    Returns help for plugin
    :return: help text
    """

    commandtext = _("This hook proceses faraday-exec results and converts to faraday for Magui plugin to work")
    return commandtext
