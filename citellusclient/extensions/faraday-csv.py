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
    if not options.live or not options.sosreport:
        yield []

    prio = 0
    if options:
        try:
            prio = options.prio
        except:
            exit

    plugins = citellus.findplugins(folders=[pluginsdir], executables=True, fileextension=".sh", extension=extension, prio=prio)
    newplugins = []
    for plugin in plugins:
        # call each plugin with positional argument '_items_' to get CSV ";" of items
        # do loop for each item and add plugin with a new value defined 
        # in the dictionary with item

        citellus.LOG.info("IRANZO")
        citellus.LOG.info(plugin)

        command = "%s %s" % (plugin['plugin'], '_items_')
        returncode, out, err = citellus.execonshell(filename=command)
        citellus.LOG.info(options.sosreport)
        results = citellus.docitellus(live=options.live, path=options.sosreport, forcerun=False, web=False, plugins=[plugin] )
        citellus.LOG.info(results)

        id = plugin['id']
        ln = plugin['description']
        for each in err.split(";"):
            newid = "%s-%s" % (id, citellus.calcid(string=each))
            update = {'item': each, 'id': newid, 'description': '%s: %s' % (ln, each)}
            plugin.update(update)
            # Append new modified plugin
            newplugins.append(plugin)
            citellus.LOG.info(plugin)

    yield []


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

    command = "%s %s" % (plugin['plugin'], plugin['item'])
    return citellus.execonshell(filename=command)


def help():  # do not edit this line
    """
    Returns help for plugin
    :return: help text
    """

    commandtext = _("This extension creates fake plugins based items/checks for metadata")
    return commandtext
