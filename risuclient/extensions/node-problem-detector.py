#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Description: Extension for processing node-problem-detector rules
# Author: Pablo Iranzo Gomez (Pablo.Iranzo@gmail.com)
# Copyright (C) 2019-2021, 2025, 2026 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>
#
from __future__ import print_function

import json
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
extension = "node-problem-detector"
pluginsdir = os.path.join(risu.risudir, "plugins", extension)


class NodeProblemDetectorExtension(BaseExtension):
    """Extension for processing node-problem-detector JSON rules"""

    extension_name = "node-problem-detector"
    file_extension = ".json"
    executables_only = False

    def listplugins(self, options=None):
        """
        List available plugins - generates multiple plugins from JSON rules
        :param options: argparse options provided
        :return: plugin object generator
        """
        prio = 0
        if options:
            try:
                prio = options.prio
            except AttributeError:
                pass

        plugins = []

        # Build folder list
        folders = [self.plugins_dir]
        if options and options.extraplugintree:
            folders.append(os.path.join(options.extraplugintree, self.extension_name))

        for plugin in risu.findplugins(
            folders=folders,
            executables=False,
            fileextension=".json",
            extension=self.extension_name,
            prio=prio,
            options=options,
        ):
            filename = plugin["plugin"]
            with open(filename, "r") as f:
                data = json.load(f)
            if "logPath" in data and "rules" in data:
                path = data["logPath"]

                for rule in data["rules"]:
                    # Clone plugin dictionary:
                    newplugin = dict(plugin)
                    newplugin["name"] = "Check %s for %s" % (path, rule["pattern"])
                    newplugin["category"] = "node-problem-detector"
                    newplugin["path"] = "%s%s" % ("${RISU_ROOT}", path)
                    newplugin["description"] = "%s: %s" % (
                        plugin["description"],
                        path.replace("${RISU_ROOT}", ""),
                    )
                    newplugin["id"] = "%s%s" % (
                        plugin["id"],
                        risu.calcid(string=rule["pattern"]),
                    )
                    newplugin["pattern"] = rule["pattern"]
                    newplugin["reason"] = rule["reason"]
                    plugins.append(dict(newplugin))

        yield plugins

    def run(self, plugin):
        """
        Check log file for pattern match
        :param plugin: plugin dictionary
        :return: returncode, out, err
        """
        filename = plugin["path"]

        if "${RISU_ROOT}" in filename:
            filename = filename.replace("${RISU_ROOT}", os.environ["RISU_ROOT"])

        pattern = plugin["pattern"]
        reason = plugin["reason"]

        out = ""
        err = ""
        returncode = risu.RC_FAILED

        if os.access(filename, os.R_OK) and os.path.isfile(filename):
            if risu.regexpfile(filename=filename, regexp=pattern):
                err = reason
                returncode = risu.RC_FAILED
            else:
                returncode = risu.RC_OKAY
        else:
            returncode = risu.RC_SKIPPED
            err = "File %s is not accessible in read mode" % filename

        return returncode, out, err

    def help(self):
        """Returns help for plugin"""
        return self._(
            "This extension creates fake plugins based on node-plugin-detector jsons"
        )


# Create module-level exports for backward compatibility
_instance = NodeProblemDetectorExtension()
init = _instance.init
listplugins = _instance.listplugins
get_metadata = _instance.get_metadata
run = _instance.run
help = _instance.help
