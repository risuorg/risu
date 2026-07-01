#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Description: Configuration management for Risu framework
# Copyright (C) 2026 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

"""
Configuration management for Risu framework.

This module provides a central configuration object that replaces
global variables and provides better state management.

Python 2.7 compatible - no dataclasses, using regular class with __init__.
"""

from __future__ import print_function

import os

try:
    from risuclient import exceptions
except ImportError:
    import exceptions


class RisuConfig(object):
    """
    Central configuration object for Risu framework.

    This class encapsulates all configuration state that was previously
    stored in global variables. It provides:
    - Clear interface to configuration
    - Easy testing (can mock config)
    - Thread-safe execution (each run gets its own config)
    - Type documentation via docstrings (Python 2.7 compatible)

    Attributes:
        risu_dir (str): Framework base directory path
        locale_dir (str): Locale/i18n directory path
        extension_folder (str): Extensions directory path
        hooks_folder (str): Hooks directory path
        plugins (list): List of discovered plugin dicts
        extensions (list): List of loaded extension modules
        extension_triggers (dict): Extension trigger mapping
        hooks (list): List of loaded hook modules
        progress_char (str): Character to use for progress indicator
        is_live (bool): True if running on live system, False for snapshot
        risu_root (str): Root of system being analyzed
        risu_tmp (str): Temporary directory for live mode
    """

    def __init__(self, base_dir=None):
        """
        Initialize configuration with default values.

        Args:
            base_dir (str, optional): Override base directory. If None,
                                     uses the directory containing this module.
        """
        # Determine base directory
        if base_dir is None:
            self.risu_dir = os.path.abspath(os.path.dirname(__file__))
        else:
            self.risu_dir = os.path.abspath(base_dir)

        # Directory paths
        self.locale_dir = os.path.join(self.risu_dir, "locale")
        self.extension_folder = os.path.join(self.risu_dir, "extensions")
        self.hooks_folder = os.path.join(self.risu_dir, "hooks")

        # Plugin and extension state
        self.plugins = []
        self.extensions = []
        self.extension_triggers = {}
        self.hooks = []

        # Display settings
        self.progress_char = "="
        self.progress_colour = None
        self.progress_start = ""
        self.progress_end = ""

        # Execution mode
        self.is_live = False
        self.risu_root = "/"
        self.risu_tmp = None

        # Processing options
        self.num_processes = None  # None means use cpu_count()
        self.timeout = 30  # Plugin execution timeout in seconds

        # Output options
        self.quiet = False
        self.verbose = 0
        self.loglevel = "INFO"

        # Filtering options
        self.include = []
        self.exclude = []
        self.priority = 0

        # Feature flags
        self.anon = False  # Anonymize output
        self.blame = False  # Report time spent on each plugin
        self.web = False  # Generate web interface

        # Paths
        self.output_file = None
        self.extra_plugin_tree = None

        # Advanced options
        self.config_file = None
        self.call_home_uri = None

    @classmethod
    def from_options(cls, options):
        """
        Create RisuConfig from argparse options.

        This factory method creates a configuration object from
        the parsed command-line arguments.

        Args:
            options: argparse.Namespace object from parse_args()

        Returns:
            RisuConfig: Configured instance

        Example:
            >>> options = parse_args()
            >>> config = RisuConfig.from_options(options)
        """
        config = cls()

        # Apply options to config
        if hasattr(options, "live"):
            config.is_live = bool(options.live)

        if hasattr(options, "sosreport") and options.sosreport:
            config.risu_root = os.path.abspath(options.sosreport)
        elif not config.is_live:
            config.risu_root = "/"

        if hasattr(options, "quiet"):
            config.quiet = bool(options.quiet)

        if hasattr(options, "verbose"):
            config.verbose = options.verbose if options.verbose else 0

        if hasattr(options, "loglevel"):
            config.loglevel = options.loglevel

        if hasattr(options, "include"):
            config.include = options.include if options.include else []

        if hasattr(options, "exclude"):
            config.exclude = options.exclude if options.exclude else []

        if hasattr(options, "prio"):
            config.priority = options.prio if options.prio else 0

        if hasattr(options, "numproc"):
            config.num_processes = options.numproc

        if hasattr(options, "output"):
            config.output_file = options.output

        if hasattr(options, "extraplugintree"):
            config.extra_plugin_tree = options.extraplugintree

        if hasattr(options, "anon"):
            config.anon = bool(options.anon)

        if hasattr(options, "blame"):
            config.blame = bool(options.blame)

        if hasattr(options, "web"):
            config.web = bool(options.web)

        if hasattr(options, "progress"):
            config.progress_char = options.progress

        if hasattr(options, "progress_colour"):
            config.progress_colour = options.progress_colour

        if hasattr(options, "progress_start"):
            config.progress_start = options.progress_start

        if hasattr(options, "progress_end"):
            config.progress_end = options.progress_end

        if hasattr(options, "call_home"):
            config.call_home_uri = options.call_home

        return config

    def get_risu_live(self):
        """
        Get RISU_LIVE value for environment.

        Returns:
            int: 1 if live mode, 0 if snapshot mode
        """
        return 1 if self.is_live else 0

    def get_env_vars(self):
        """
        Get environment variables for plugin execution.

        Returns a dictionary of environment variables that should be
        set when executing plugins.

        Returns:
            dict: Environment variables for plugins
        """
        env = {
            "RISU_BASE": self.risu_dir,
            "RISU_LIVE": str(self.get_risu_live()),
            "RISU_ROOT": self.risu_root,
        }

        if self.risu_tmp:
            env["RISU_TMP"] = self.risu_tmp

        return env

    def validate(self):
        """
        Validate configuration.

        Checks that all required paths exist and values are valid.

        Raises:
            exceptions.ConfigError: If configuration is invalid

        Returns:
            bool: True if valid
        """
        # Check that base directories exist
        if not os.path.isdir(self.risu_dir):
            raise exceptions.ConfigError(
                "Risu directory does not exist: %s" % self.risu_dir
            )

        if not os.path.isdir(self.extension_folder):
            raise exceptions.ConfigError(
                "Extension folder does not exist: %s" % self.extension_folder
            )

        # Check risu_root exists (unless live mode)
        if not self.is_live:
            if not os.path.isdir(self.risu_root):
                raise exceptions.ConfigError(
                    "Target directory does not exist: %s" % self.risu_root
                )

        # Validate priority range
        if not (0 <= self.priority <= 1000):
            raise exceptions.ConfigError(
                "Priority must be 0-1000, got: %d" % self.priority
            )

        # Validate timeout
        if self.timeout <= 0:
            raise exceptions.ConfigError(
                "Timeout must be positive, got: %d" % self.timeout
            )

        return True

    def __repr__(self):
        """String representation for debugging."""
        return (
            "RisuConfig(is_live=%r, risu_root=%r, priority=%d, "
            "plugins=%d, extensions=%d)"
            % (
                self.is_live,
                self.risu_root,
                self.priority,
                len(self.plugins),
                len(self.extensions),
            )
        )
