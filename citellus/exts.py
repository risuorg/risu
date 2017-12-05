#!/usr/bin/env python
# encoding: utf-8
#
# Description: Extensions loader
# Author: Pablo Iranzo Gómez (Pablo.Iranzo@gmail.com

from __future__ import print_function

import imp
import os
import logging
LOG = logging.getLogger('citellus.exts')

citellusdir = os.path.abspath(os.path.dirname(__file__))

ExtensionFolder = os.path.join(citellusdir, "extensions")


def getExtensions():
    """
    Gets list of Extensions in the Extensions folder
    :return: list of Extensions available
    """

    Extensions = []
    possibleExtensions = os.listdir(ExtensionFolder)
    for i in possibleExtensions:
        if i != "__init__.py" and os.path.splitext(i)[1] == ".py":
            i = os.path.splitext(i)[0]
        try:
            info = imp.find_module(i, [ExtensionFolder])
        except:
            info = False
        if i and info:
            Extensions.append({"name": i, "info": info})

    return Extensions


def loadExtension(Extension):
    """
    Loads selected Extension
    :param Extension: Extension to load
    :return: loader for Extension
    """
    return imp.load_module(Extension["name"], *Extension["info"])


def initExtensions():
    """
    Initializes Extensions
    :return: list of Extension modules initialized
    """

    exts = []
    for i in getExtensions():
        newplug = loadExtension(i)
        exts.append(newplug)
    return exts
