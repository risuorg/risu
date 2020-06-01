#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Description: Extension for processing node-problem-detector rules
# Author: Pablo Iranzo Gomez (Pablo.Iranzo@gmail.com)
# Copyright (C) 2019, 2020 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>
#

from __future__ import print_function

import os
import json

try:
    import citellusclient.shell as citellus
except:
    import shell as citellus

# Load i18n settings from citellus
_ = citellus._

extension = "node-problem-detector"
pluginsdir = os.path.join(citellus.citellusdir, "plugins", extension)


def init():
    """
    Initializes module
    :return: List of triggers for extension
    """
    triggers = ["node-problem-detector"]
    return triggers


def listplugins(options=None):
    """
    List available plugins
    :param options: argparse options provided
    :return: plugin object generator
    """

    prio = 0
    if options:
        try:
            prio = options.prio
        except:
            pass

    plugins = []

    if options and options.extraplugintree:
        folders = [pluginsdir, os.path.join(options.extraplugintree, extension)]
    else:
        folders = [pluginsdir]

    for plugin in citellus.findplugins(
        folders=folders,
        executables=False,
        fileextension=".json",
        extension=extension,
        prio=prio,
        options=options,
    ):
        filename = plugin["plugin"]
        data = json.load(open(filename, "r"))
        if "logPath" in data and "rules" in data:
            path = data["logPath"]

            for rule in data["rules"]:
                # Clone plugin dictionary:
                newplugin = dict(plugin)
                newplugin["name"] = "Check %s for %s" % (path, rule["pattern"])
                newplugin["category"] = "node-problem-detector"
                newplugin["path"] = "%s%s" % ("${CITELLUS_ROOT}", path)
                newplugin["description"] = "%s: %s" % (
                    plugin["description"],
                    path.replace("${CITELLUS_ROOT}", ""),
                )
                newplugin["id"] = "%s%s" % (
                    plugin["id"],
                    citellus.calcid(string=rule["pattern"]),
                )
                newplugin["pattern"] = rule["pattern"]
                newplugin["reason"] = rule["reason"]
                plugins.append(dict(newplugin))

    yield plugins


def get_metadata(plugin):
    """
    Gets metadata for plugin
    :param plugin: plugin object
    :return: metadata dict for that plugin
    """

    return citellus.generic_get_metadata(plugin)


def run(plugin):  # do not edit this line
    """
    Executes plugin
    : return: returncode, out, err
    """

    filename = plugin["path"]

    if "${CITELLUS_ROOT}" in filename:
        filename = filename.replace("${CITELLUS_ROOT}", os.environ["CITELLUS_ROOT"])

    pattern = plugin["pattern"]
    reason = plugin["reason"]

    out = ""
    err = ""
    returncode = citellus.RC_FAILED

    if os.access(filename, os.R_OK) and os.path.isfile(filename):
        if citellus.regexpfile(filename=filename, regexp=pattern):
            err = reason
            returncode = citellus.RC_FAILED
        else:
            returncode = citellus.RC_OKAY
    else:
        returncode = citellus.RC_SKIPPED
        err = "File %s is not accessible in read mode" % filename

    return returncode, out, err


def help():  # do not edit this line
    """
    Returns help for plugin
    :return: help text
    """

    commandtext = _(
        "This extension creates fake plugins based on node-plugin-detector jsons"
    )
    return commandtext
