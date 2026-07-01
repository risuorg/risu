#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Description: Extension for processing GOlang Risu plugins
# Author: Pablo Iranzo Gomez (Pablo.Iranzo@gmail.com)
# Copyright (C) 2020, 2021, 2026 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>
from __future__ import print_function

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
extension = "golang"
pluginsdir = os.path.join(risu.risudir, "plugins", extension)


class GolangExtension(BaseExtension):
    """Extension for processing Go language plugins"""

    extension_name = "golang"
    file_extension = ".go"
    executables_only = False
    comment_char = "//"

    def run(self, plugin):
        """
        Compile and execute Go plugin
        :param plugin: plugin dictionary
        :return: returncode, out, err
        """
        gorun = risu.which("go")
        if not gorun:
            return risu.RC_SKIPPED, "", self._("Golang support not found")

        filename = plugin["plugin"]

        # Save current directory
        mypath = os.getcwd()

        path = os.path.dirname(filename)
        file = os.path.basename(filename)

        # Compiling
        binary = os.path.splitext(filename)[0]

        os.chdir(path)
        try:
            os.remove(binary)
        except OSError:
            pass
        command = "%s build %s" % (gorun, file)

        risu.execonshell(filename=command)

        # Go back to our folder
        os.chdir(mypath)

        # Running
        returncode, out, err = risu.execonshell(filename=binary)

        return returncode, out, err

    def help(self):
        """Returns help for plugin"""
        return self._("This extension proceses Risu golang plugins")


# Create module-level exports for backward compatibility
_instance = GolangExtension()
init = _instance.init
listplugins = _instance.listplugins
get_metadata = _instance.get_metadata
run = _instance.run
help = _instance.help
