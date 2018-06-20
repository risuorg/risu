#!/usr/bin/env python
# encoding: utf-8
#
# Description: Hook for moving Mpath global results to individual tests results
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

    mpathids = citellus.calcid(string='/plugins/faraday/positive/system/multipathluns.sh')
    # Loop over plugin id's in data
    for pluginid in data:
        if data[pluginid]['id'] == mpathids:
            # Make a copy of dict for working on it
            plugin = dict(data[pluginid])

            # Add plugin ID to be removed for resulting data so magui doesn't compare the whole set of nics at the same time
            idstodel.append(str(pluginid))

            err = str(plugin['result']['err'])
            rc = int(plugin['result']['rc'])
            plugpath = str(plugin['plugin'])
            id = str(plugin['id'])
            ln = str(plugin['long_name'])
            desc = str(plugin['description'])

            # Iterate over NIC pairs
            if ";" in err:
                for pair in err.split(";"):
                    if pair != '':
                        # For each device:size pair, split on ":" for LUN/size and fake plugin entry
                        newid = "%s-%s" % (id, citellus.calcid(string=pair.split(":")[0]))
                        update = {'id': newid, 'description': '%s: %s' % (desc, pair.split(":")[0]),
                                  'long_name': '%s: %s' % (ln, pair.split(":")[0]),
                                  'plugin': '%s-%s' % (plugpath, pair.split(":")[0]),
                                  'name': 'mpath: %s' % pair.split(":")[0]}

                        resultupdate = {'result': {'err': pair, 'out': '', 'rc': rc}}
                        update.update(resultupdate)

                        # Update plugin dictionary with forged values
                        plugin.update(dict(update))

                        plugin['result']['err'] = str(pair)

                        # Append new modified plugin to dataset
                        datatoadd.append({newid: dict(plugin)})

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
