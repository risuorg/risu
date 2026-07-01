#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Description: Extension for processing file affinities/antiaffinities to be reported in a
#              similar way to metadata and later processed by corresponding plugin in Magui
#
# Author: Pablo Iranzo Gomez (Pablo.Iranzo@gmail.com)
# Copyright (C) 2018 Robin Černín <cerninr@gmail.com>
# Copyright (C) 2018-2021, 2023, 2026 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>
from __future__ import print_function

import os

try:
    import risuclient.shell as risu
    from risuclient.extensions.base import SimpleShellExtension
except ImportError:
    import shell as risu
    from extensions.base import SimpleShellExtension

# Load i18n settings from risu (for backward compatibility)
_ = risu._

# Legacy module-level variables (for backward compatibility)
extension = "faraday-exec"
# We look for plugins in standard faraday path
pluginsdir = os.path.join(risu.risudir, "plugins", "faraday")


class FaradayExecExtension(SimpleShellExtension):
    """Extension for executing shell-based faraday plugins"""

    extension_name = "faraday-exec"
    plugins_subdir = "faraday"  # Use faraday subdirectory
    file_extension = ".sh"

    def get_metadata(self, plugin):
        """Get metadata for plugin with category/subcategory extraction"""
        metadata = risu.generic_get_metadata(plugin=plugin)

        subcategory = os.path.split(plugin["plugin"])[0].replace(
            os.path.join(risu.risudir, "plugins", "faraday"), ""
        )
        category = os.path.normpath(subcategory).split(os.sep)[1] or ""
        metadata.update({"subcategory": subcategory, "category": category})

        return metadata

    def help(self):
        """Returns help for plugin"""
        return self._(
            "This extension creates fake plugins based on affinity/antiaffinity file list for later processing"
        )


# Create module-level exports for backward compatibility
_instance = FaradayExecExtension()
init = _instance.init
listplugins = _instance.listplugins
get_metadata = _instance.get_metadata
run = _instance.run
help = _instance.help
