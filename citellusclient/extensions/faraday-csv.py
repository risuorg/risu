#!/usr/bin/env python
# encoding: utf-8
#
# Description: Extension for processing file affinities/antiaffinities to be reported in a
#              similar way to metadata and later processed by corresponding plugin in Magui
#              As oposed to exec and regular faraday, this one is based on exec approach but
#              does expand the execution results as additional 'plugins and metadata'
#
# Author: Pablo Iranzo Gomez (Pablo.Iranzo@gmail.com)

from __future__ import print_function

import os

try:
    import citellusclient.shell as citellus
except:
    import shell as citellus

# Load i18n settings from citellus
_ = citellus._

extension = "faraday-csv"
# We look for plugins in standard faraday path
pluginsdir = os.path.join(citellus.citellusdir, 'plugins', 'faraday-csv')


def init():
    """
    Initializes module
    :return: List of triggers for extension
    """
    triggers = ['faraday-exec']
    return triggers


def listplugins(options=None):
    """
    List available plugins
    :param options: argparse options provided
    :return: plugin object generator
    """

    # Exit if we're not running live or from sosreport (like when listing plugins)
    if options:
        if 'live' in options:
            live = options.live
        else:
            live = False
        if 'sosreport' in options:
            sosreport = options.sosreport
        else:
            sosreport = None
        prio = options.prio
    else:
        live = False
        sosreport = None
        prio = 0

    # Grab all the plugins for faraday-csv and set the dictionary to contain 'item' prefilled
    farcsvplugins = citellus.findplugins(folders=[pluginsdir], executables=True, fileextension=".sh", extension=extension, prio=prio, dictupdate={'item': '_items_'})

    # Use citellus to grab the data each one can deliver
    results = citellus.docitellus(live=live, path=sosreport, forcerun=True, web=False, plugins=farcsvplugins, dontsave=True)

    newplugins = []
    for result in results:
        # Grab the output of plugin and use it as dict for what we'll be overwriting
        plugin = dict(results[result])
        err = str(plugin['result']['err'])
        plugpath = str(plugin['plugin'])
        id = str(plugin['id'])
        ln = str(plugin['long_name'])
        desc = str(plugin['description'])

        # Remove result from fake execution to get items
        del plugin['result']

        # Separate for each 'CSV' value that it provides and create a fake plugin for it updating dict items
        for each in err.split(";"):
            if each:
                newid = "%s-%s" % (id, citellus.calcid(string=each))
                update = {'item': each, 'id': newid, 'description': '%s: %s' % (desc, each), 'long_name': '%s: %s' % (ln, each), 'plugin': '%s-%s' % (plugpath, each)}

                # Update plugin dictionary with forged values
                plugin.update(update)
                # Append new modified plugin
                newplugins.append(dict(plugin))
    yield newplugins


def get_metadata(plugin):
    """
    Gets metadata for plugin
    :param plugin: plugin object
    :return: metadata dict for that plugin
    """

    subcategory = os.path.split(plugin['plugin'])[0].replace(pluginsdir, '')[1:]
    metadata = {'description': citellus.regexpfile(filename=plugin['plugin'], regexp='\A# description:')[14:].strip(),
                'long_name': citellus.regexpfile(filename=plugin['plugin'], regexp='\A# long_name:')[12:].strip(),
                'bugzilla': citellus.regexpfile(filename=plugin['plugin'], regexp='\A# bugzilla:')[11:].strip(),
                'priority': int(citellus.regexpfile(filename=plugin['plugin'], regexp='\A# priority:')[11:].strip() or 0),
                'subcategory': subcategory,
                'category': os.path.normpath(subcategory).split(os.sep)[1] or ''}
    return metadata


def run(plugin):  # do not edit this line
    """
    Executes plugin with item argument
    :return: returncode, out, err
    """

    if 'item' not in plugin:
        plugin['item'] = ''
    command = "%s %s" % (plugin['plugin'], plugin['item'])
    return citellus.execonshell(filename=command)


def help():  # do not edit this line
    """
    Returns help for plugin
    :return: help text
    """

    commandtext = _("This extension creates fake plugins based items/checks for metadata")
    return commandtext
