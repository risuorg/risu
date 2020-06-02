#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Description: Hook for procesing profile definitions and appending results formated to json
# Author: Pablo Iranzo Gomez (Pablo.Iranzo@gmail.com)
# Copyright (C) 2018, 2019, 2020 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

from __future__ import print_function

import json
import os
import re

try:
    import citellusclient.shell as citellus
except:
    import shell as citellus

# Load i18n settings from citellus
_ = citellus._

extension = "profiles"
pluginsdir = os.path.join(citellus.citellusdir, "plugins", extension)


def init():
    """
    Initializes module
    :return: List of triggers for extension
    """
    return []


def plugidsforprofile(profile, plugins):
    """
    Gets plugin id's related with profile includes/excludes
    :param profile: profile file to open
    :param plugins: plugins in citellus execution
    :return: array of id's
    """
    # Open Profile definition for read and fill filters for plugins
    include = []
    exclude = []
    with open(profile, "r") as f:
        for line in f:
            if re.match(r"\A\+.*", line):
                include.append(line[1:].strip())
            if re.match(r"\A\-.*", line):
                exclude.append(line[1:].strip())
    ids = citellus.getids(plugins=plugins, include=include, exclude=exclude)

    return ids


def run(data, quiet=False, options=None):  # do not edit this line
    """
    Executes plugin
    :param quiet: be more silent on returned information
    :param data: data to process
    :return: returncode, out, err
    """

    # prefill plugins we had used:
    plugins = []
    for item in data:
        plugin = {"plugin": data[item]["plugin"], "id": data[item]["id"]}
        plugins.append(plugin)

    if options and options.extraplugintree:
        folders = [pluginsdir, os.path.join(options.extraplugintree, extension)]
    else:
        folders = [pluginsdir]

    # Find available profile definitions
    profiles = citellus.findplugins(
        folders=folders, executables=False, fileextension=".txt"
    )
    for item in profiles:
        uid = citellus.getids(plugins=[item])[0]
        profile = item["plugin"]

        plugin = dict(item)

        # Precreate storage for this profile
        name = "Profiles: %s" % os.path.basename(
            os.path.splitext(profile.replace(pluginsdir, ""))[0]
        )
        subcategory = ""
        category = name

        data[uid] = {
            "category": category,
            "hash": item["hash"],
            "plugin": item["plugin"],
            "name": name,
            "result": {"rc": 0, "err": "", "out": ""},
            "time": 0,
            "backend": "profile",
            "id": uid,
            "subcategory": subcategory,
        }

        metadata = {
            "description": citellus.regexpfile(
                filename=plugin["plugin"], regexp=r"\A# description:"
            )[14:].strip(),
            "long_name": citellus.regexpfile(
                filename=plugin["plugin"], regexp=r"\A# long_name:"
            )[12:].strip(),
            "bugzilla": citellus.regexpfile(
                filename=plugin["plugin"], regexp=r"\A# bugzilla:"
            )[11:].strip(),
            "priority": int(
                citellus.regexpfile(filename=plugin["plugin"], regexp=r"\A# priority:")[
                    11:
                ].strip()
                or 0
            ),
        }
        data[uid].update(metadata)

        # start with OK status
        okay = int(os.environ["RC_OKAY"])
        failed = int(os.environ["RC_FAILED"])
        skipped = int(os.environ["RC_SKIPPED"])
        info = int(os.environ["RC_INFO"])

        # Start asembling data for the plugins relevant for profile
        data[uid]["result"]["err"] = ""
        ids = plugidsforprofile(profile=profile, plugins=plugins)

        new_results = []
        overallitems = []

        for id in ids:
            if id in data:
                if "sysinfo" in name and data[id]["result"]["rc"] == skipped:
                    # Do nothing as we don't want to show skipped in sysinfo
                    pass
                else:
                    new_results.append(
                        {
                            "plugin_id": id,
                            "plugin": data[id]["plugin"].replace(
                                os.path.join(citellus.citellusdir, "plugins"), ""
                            ),
                            "err": data[id]["result"]["err"].strip(),
                            "rc": data[id]["result"]["rc"],
                        }
                    )
                    overallitems.append(data[id]["result"]["rc"])

        if "sysinfo" in name:
            if okay in overallitems or failed in overallitems or info in overallitems:
                overall = info
            else:
                # No plugins matched, so skip it
                overall = skipped
        else:
            if failed in overallitems:
                overall = failed
            elif info in overallitems:
                overall = info
            elif skipped in overallitems:
                overall = skipped
            else:
                overall = okay

        data[uid]["result"]["err"] = json.dumps(new_results)
        data[uid]["components"] = ids
        data[uid]["result"]["rc"] = overall

    return data


def help():  # do not edit this line
    """
    Returns help for plugin
    :return: help text
    """

    commandtext = _(
        "This hook proceses Citellus profiles and assembles data for each one to be appended to results json"
    )
    return commandtext
