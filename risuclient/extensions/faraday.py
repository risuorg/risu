#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Description: Extension for processing file affinities/antiaffinities to be reported in a
#              similar way to metadata and later processed by corresponding plugin in Magui
#
# Author: Pablo Iranzo Gomez (Pablo.Iranzo@gmail.com)
# Copyright (C) 2018-2021, 2023, 2026 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>
from __future__ import print_function

import hashlib
import os

try:
    import risuclient.shell as risu
    from risuclient.extensions.base import BaseExtension
except ImportError:
    import shell as risu
    from extensions.base import BaseExtension

# Load i18n settings from risu (for backward compatibility)
_ = risu._

# Legacy module-level variables (for backward compatibility)
extension = "faraday"
pluginsdir = os.path.join(risu.risudir, "plugins", extension)


class FaradayExtension(BaseExtension):
    """Extension for processing file affinity/antiaffinity plugins"""

    extension_name = "faraday"
    file_extension = ".txt"
    executables_only = False

    def listplugins(self, options=None):
        """
        List available plugins with comma-separated path expansion
        :param options: argparse options provided
        :return: plugin object generator
        """
        prio = 0
        if options:
            try:
                prio = options.prio
            except AttributeError:
                pass

        # Build folder list
        folders = [self.plugins_dir]
        if options and options.extraplugintree:
            folders.append(os.path.join(options.extraplugintree, self.extension_name))

        plugins = risu.findplugins(
            folders=folders,
            executables=False,
            fileextension=".txt",
            extension=self.extension_name,
            prio=prio,
            options=options,
        )

        # Check for multiple files specified as per the 'path' by using "," as separator
        newplugins = []
        for plugin in plugins:
            if "," not in plugin["path"]:
                newplugins.append(plugin)
            else:
                # Path contains ',' so we fake extra plugins for each path
                for path in plugin["path"].split(","):
                    # Clone plugin dictionary:
                    newplugin = dict(plugin)
                    newplugin["name"] = "Check %s" % path.replace("${RISU_ROOT}", "")
                    newplugin["path"] = path
                    newplugin["description"] = "%s: %s" % (
                        plugin["description"],
                        path.replace("${RISU_ROOT}", ""),
                    )
                    newplugin["id"] = "%s-%s" % (plugin["id"], risu.calcid(string=path))
                    newplugins.append(newplugin)

        yield newplugins

    def run(self, plugin):
        """
        Calculate file hash for affinity checking
        :param plugin: plugin dictionary
        :return: returncode, out, err
        """
        filename = plugin["path"]

        skipped = 0
        if os.environ["RISU_LIVE"] == 0 and risu.regexpfile(
            filename=filename, regexp="RISU_ROOT"
        ):
            # We're running in snapshot and faraday file has RISU_ROOT
            skipped = 0
        else:
            if os.environ["RISU_LIVE"] == 1:
                if risu.regexpfile(
                    filename=plugin["plugin"], regexp="RISU_HYBRID"
                ) or not risu.regexpfile(filename=filename, regexp="RISU_ROOT"):
                    # We're running in Live mode and either plugin supports HYBRID or has no RISU_ROOT
                    skipped = 0
                else:
                    # We do not satisfy conditions, exit early
                    skipped = 1

        if skipped == 1:
            return (
                risu.RC_SKIPPED,
                "",
                self._("Plugin does not satisfy conditions for running"),
            )

        if "${RISU_ROOT}" in filename:
            filename = filename.replace("${RISU_ROOT}", os.environ["RISU_ROOT"])

        if os.access(filename, os.R_OK):
            # We can read the file, so let's calculate hash
            out = ""
            err = hashlib.sha512(open(filename, "rb").read()).hexdigest()
            returncode = risu.RC_OKAY
        else:
            returncode = risu.RC_SKIPPED
            out = ""
            err = "File %s is not accessible in read mode" % filename

        return returncode, out, err

    def help(self):
        """Returns help for plugin"""
        return self._(
            "This extension creates fake plugins based on affinity/antiaffinity file list for later processing"
        )


# Create module-level exports for backward compatibility
_instance = FaradayExtension()
init = _instance.init
listplugins = _instance.listplugins
get_metadata = _instance.get_metadata
run = _instance.run
help = _instance.help
