#!/usr/bin/env python
# encoding: utf-8
#
# Description: Hook for putting citellus kbase on top of results
# Author: Pablo Iranzo Gomez (Pablo.Iranzo@gmail.com)

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

    # Use calculated ID instead of getid because of execution loop
    fakeid = citellus.calcid(string=__file__)

    # load here branding
    string = _("                                                  ")

    if 'GSS' in string:
        # start with FAILED status
        failed = int(os.environ['RC_FAILED'])

        # We now fake results to list kbase for linking
        fakedata = {"category": "support",
                    "hash": "c6e2fd181c31e921b3a9b1c3677f143c",
                    "description": "Reports kbase for Citellus information",
                    "plugin": __file__,
                    "name": "Citellus Kbase reporter",
                    "priority": 1000,
                    "long_name": "https://access.redhat.com/solutions/3405671",
                    "bugzilla": "",
                    "result": {"rc": failed,
                               "err": "Please do link provided kbase https://access.redhat.com/solutions/3405671 for metrics on usefulness of the tool",
                               "out": ""},
                    "time": 0,
                    "backend": "core",
                    "id": fakeid,
                    "subcategory": "gss/cee"}
        data.update({fakeid: fakedata})

    return data


def help():  # do not edit this line
    """
    Returns help for plugin
    :return: help text
    """

    commandtext = _("This hook proceses citellus outputs and appends kbase to link to cases where citellus helped")
    return commandtext
