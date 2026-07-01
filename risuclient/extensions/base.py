#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Description: Base class for all Risu extensions
# Author: Pablo Iranzo Gomez (Pablo.Iranzo@gmail.com)
# Copyright (C) 2026 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

from __future__ import print_function

import os

try:
    import risuclient.shell as risu
except ImportError:
    import shell as risu


class BaseExtension(object):
    """
    Base class for all Risu extensions.

    Provides common functionality for plugin discovery, metadata extraction,
    and execution. Subclasses should override extension_name and run().

    Attributes:
        extension_name: Name of the extension (e.g., "core", "ansible")
        plugins_subdir: Subdirectory in plugins/ (defaults to extension_name)
        file_extension: File extension for plugins (e.g., ".yml" for ansible)
        executables_only: True if only executable files are plugins
        comment_char: Comment character for metadata extraction
    """

    # Class attributes - override in subclasses
    extension_name = None  # MUST be set in subclass
    plugins_subdir = None  # Defaults to extension_name if not set
    file_extension = None  # E.g., ".yml", ".go" - None means any file
    executables_only = True  # False for ansible, metadata
    comment_char = "#"  # Comment character for metadata

    def __init__(self):
        """Initialize the extension"""
        if self.extension_name is None:
            raise NotImplementedError("extension_name must be set in subclass")

        # Set plugins directory
        subdir = self.plugins_subdir or self.extension_name
        self.plugins_dir = os.path.join(risu.risudir, "plugins", subdir)

        # Load i18n from risu
        self._ = risu._

    def init(self):
        """
        Initialize module and return triggers.

        :return: List of triggers for extension

        Triggers are used to match plugins to their extension.
        Default is [extension_name].
        """
        return [self.extension_name]

    def listplugins(self, options=None):
        """
        List available plugins for this extension.

        :param options: argparse options provided
        :return: plugin object generator

        Yields a list of plugins found in the plugins directory.
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

        # Find plugins with appropriate parameters
        yield risu.findplugins(
            folders=folders,
            prio=prio,
            options=options,
            executables=self.executables_only,
            fileextension=self.file_extension,
            extension=self.extension_name,
        )

    def get_metadata(self, plugin):
        """
        Get metadata for a plugin.

        :param plugin: plugin object
        :return: metadata dict for that plugin

        Default implementation uses generic_get_metadata with the
        appropriate comment character. Subclasses can override for
        custom metadata extraction (e.g., YAML parsing for ansible).
        """
        return risu.generic_get_metadata(plugin=plugin, comment=self.comment_char)

    def run(self, plugin):
        """
        Execute a plugin.

        :param plugin: plugin dictionary
        :return: tuple of (returncode, out, err)

        This method MUST be implemented in subclasses.
        """
        raise NotImplementedError("run() must be implemented in subclass")

    def help(self):
        """
        Return help text for this extension.

        :return: help text string

        Default implementation returns a generic message.
        Subclasses can override for custom help.
        """
        return self._("This extension processes %s plugins") % self.extension_name


class SimpleShellExtension(BaseExtension):
    """
    Extension for simple shell script execution.

    This is the base for extensions that just execute shell scripts
    or commands (core, golang after compilation, etc.).
    """

    def run(self, plugin):
        """
        Execute plugin as a shell command.

        :param plugin: plugin dictionary
        :return: tuple of (returncode, out, err)
        """
        return risu.execonshell(filename=plugin["plugin"])


# Helper functions for creating extension module exports
def create_extension_exports(extension_class):
    """
    Create the standard module-level exports for an extension.

    This helper creates the init(), listplugins(), get_metadata(),
    run(), and help() functions that delegate to an extension instance.

    :param extension_class: Extension class to instantiate
    :return: dict of function exports

    Usage in extension module:
        from risuclient.extensions.base import BaseExtension, create_extension_exports

        class MyExtension(BaseExtension):
            extension_name = "myext"
            def run(self, plugin):
                # ...

        # Create module exports
        _instance = MyExtension()
        init = _instance.init
        listplugins = _instance.listplugins
        get_metadata = _instance.get_metadata
        run = _instance.run
        help = _instance.help
    """
    instance = extension_class()
    return {
        "init": instance.init,
        "listplugins": instance.listplugins,
        "get_metadata": instance.get_metadata,
        "run": instance.run,
        "help": instance.help,
    }
