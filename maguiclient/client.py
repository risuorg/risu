#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Description: MaguiClient class for multi-system analysis
# Copyright (C) 2026 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

from __future__ import print_function

import copy
import hashlib
import logging
import os
import time

try:
    from maguiclient import autogroup as autogroup_module
    from risuclient import shell as risu
except ImportError:
    import autogroup as autogroup_module
    import shell as risu

LOG = logging.getLogger("magui")


class MaguiClient(object):
    """
    Multi-system analysis client for Risu.

    Coordinates execution of Risu across multiple sosreports and
    enables comparative analysis through autogroups and magui plugins.
    """

    def __init__(self, options=None):
        """
        Initialize MaguiClient.

        :param options: Parsed command-line options
        """
        self.options = options
        self.autogroup_manager = autogroup_module.AutoGroupManager()

        # Extract settings from options
        if options:
            self.forcerun = options.run
            self.include = options.include
            self.exclude = options.exclude
            self.hosts = options.hosts if hasattr(options, "hosts") else None
            self.quiet = options.quiet if hasattr(options, "quiet") else False
        else:
            self.forcerun = False
            self.include = None
            self.exclude = None
            self.hosts = None
            self.quiet = False

    def call_risu(self, path, plugins, forcerun=None, include=None, exclude=None):
        """
        Execute risu against a single sosreport.

        :param path: Path to sosreport
        :param plugins: List of plugins to run
        :param forcerun: Force re-run of risu (ignore cached results)
        :param include: Include filter patterns
        :param exclude: Exclude filter patterns
        :return: Dictionary of results keyed by plugin ID
        """
        # Use instance defaults if not provided
        if forcerun is None:
            forcerun = self.forcerun
        if include is None:
            include = self.include
        if exclude is None:
            exclude = self.exclude

        # Call risu normally
        results = risu.dorisu(
            path=os.path.abspath(path),
            plugins=plugins,
            forcerun=forcerun,
            include=include,
            exclude=exclude,
            quiet=True,
        )

        # Process plugin output - convert to dict keyed by plugin ID
        new_dict = {}
        for item in results:
            name = results[item]["id"]
            new_dict[name] = dict(results[item])

        return new_dict

    def collect_risu_results(self, sosreports, risuplugins):
        """
        Collect risu results from all sosreports.

        :param sosreports: List of sosreport paths
        :param risuplugins: List of plugins to run
        :return: Dictionary of {sosreport: {plugin_id: result}}
        """
        result = {}

        for sosreport in sosreports:
            result[sosreport] = self.call_risu(
                path=os.path.abspath(sosreport),
                plugins=risuplugins,
            )

        # Sanity check for inconsistencies
        if not self.forcerun:
            result = self._sanity_check_results(sosreports, result, risuplugins)

        return result

    def _sanity_check_results(self, sosreports, result, risuplugins):
        """
        Check for missing data and force rerun if needed.

        :param sosreports: List of sosreport paths
        :param result: Current results dictionary
        :param risuplugins: List of plugins
        :return: Updated results dictionary
        """
        # Prefill all plugins
        plugins = []
        for sosreport in sosreports:
            for plugin in result[sosreport]:
                plugins.append(plugin)

        plugins = sorted(set(plugins))

        # Check all sosreports for data for all plugins
        for sosreport in sosreports:
            rerun = False

            for plugin in plugins:
                # Skip composed plugins as they will cause rerun
                if "-" not in plugin:
                    try:
                        result[sosreport][plugin]["result"]
                    except (KeyError, TypeError):
                        rerun = True
                        break

            # If running against just JSON folder, cancel rerun
            if rerun:
                try:
                    access = os.access(os.path.join(sosreport, "version.txt"), os.R_OK)
                except (OSError, TypeError):
                    access = False

                if not access:
                    # Just a folder with JSON, skip rerun
                    rerun = False

            # Force rerun but not if we have ansible hosts
            if rerun and not self.hosts:
                LOG.debug(
                    "Forcing rerun of risu for %s because of missing plugin data"
                    % sosreport
                )
                result[sosreport] = self.call_risu(
                    path=os.path.abspath(sosreport),
                    plugins=risuplugins,
                    forcerun=True,
                )

        return result

    def group_results_by_plugin(self, sosreports, result):
        """
        Reorganize results from {sosreport: {plugin: result}}
        to {plugin: {sosreport: result}}.

        :param sosreports: List of sosreport paths
        :param result: Results dictionary
        :return: Grouped dictionary
        """
        # Precreate multidimensional array
        grouped = {}
        for sosreport in sosreports:
            plugins = []
            for plugin in result[sosreport]:
                plugins.append(plugin)
                grouped[plugin] = {}
                grouped[plugin]["sosreport"] = {}

        # Fill the data
        for sosreport in sosreports:
            for plugin in result[sosreport]:
                grouped[plugin]["sosreport"][sosreport] = result[sosreport][plugin][
                    "result"
                ]
                for element in result[sosreport][plugin]:
                    # Skip sosreport-specific elements
                    if element not in ["time", "result"]:
                        grouped[plugin][element] = result[sosreport][plugin][element]

        return grouped

    def run_hooks(self, grouped, hooks_folder):
        """
        Run processing hooks on grouped results.

        :param grouped: Grouped results dictionary
        :param hooks_folder: Path to hooks folder
        :return: Updated grouped results
        """
        for maguihook in risu.initPymodules(
            extensions=risu.getPymodules(options=self.options, folders=[hooks_folder])
        )[0]:
            LOG.debug("Running hook: %s" % maguihook.__name__.split(".")[-1])
            newresults = maguihook.run(data=copy.deepcopy(grouped))
            if newresults:
                grouped = newresults

        return grouped

    def cleanup_grouped_results(self, sosreports, grouped):
        """
        Clean up grouped results for sosreports we're not interested in.

        :param sosreports: List of sosreports to keep
        :param grouped: Grouped results
        :return: Cleaned grouped results
        """
        cleansosreports = []

        for plugin in grouped:
            # Walk plugins
            for sosreport in grouped[plugin]["sosreport"]:
                # Walk sosreports for plugin
                if sosreport not in sosreports:
                    # Add sosreport to cleanup list
                    cleansosreports.append(sosreport)

        for sosreport in sorted(set(cleansosreports)):
            for plugin in grouped:
                if sosreport in grouped[plugin]["sosreport"]:
                    del grouped[plugin]["sosreport"][sosreport]

        return grouped

    def analyze(
        self, sosreports, risuplugins, grouped=None, runhooks=True, hooks_folder=None
    ):
        """
        Main analysis method - analyze multiple sosreports.

        :param sosreports: List of sosreport paths
        :param risuplugins: List of risu plugins to run
        :param grouped: Pre-existing grouped results (optional)
        :param runhooks: Whether to run magui hooks
        :param hooks_folder: Path to hooks folder
        :return: Grouped results dictionary
        """
        if grouped is not None and grouped != {}:
            # Use provided grouped data, just clean it up
            grouped = self.cleanup_grouped_results(sosreports, grouped)
        else:
            # Collect fresh data
            result = self.collect_risu_results(sosreports, risuplugins)

            # Reorganize by plugin
            grouped = self.group_results_by_plugin(sosreports, result)

        # Run hooks if requested
        if runhooks and hooks_folder:
            grouped = self.run_hooks(grouped, hooks_folder)

        return grouped

    def filter_results(self, data, triggers):
        """
        Filter results for only the data that a plugin will use.

        :param data: Full set of grouped data
        :param triggers: Set of triggers (plugin IDs) to match
        :return: Filtered data
        """
        if "*" in triggers:
            # If plugin processes everything, return all data
            return data

        ourdata = {}
        for trigger in triggers:
            for elem in data:
                # Handle 'faked' IDs like multi-Faraday bundles
                if "id" in data[elem] and trigger in data[elem]["id"]:
                    ourdata[data[elem]["id"]] = dict(data[elem])
        return ourdata

    def run_magui_plugins(self, grouped, magui_plugins, magui_triggers, start_time):
        """
        Execute magui plugins on grouped data.

        :param grouped: Grouped results data
        :param magui_plugins: List of magui plugin modules
        :param magui_triggers: Dictionary of plugin triggers
        :param start_time: Analysis start time
        :return: List of magui plugin results
        """
        result = []

        for plugin in magui_plugins:
            plugstart_time = time.time()

            # Get output from plugin
            plugin_name = plugin.__name__.split(".")[-1]
            data = self.filter_results(
                data=grouped, triggers=magui_triggers.get(plugin_name, [])
            )

            returncode, out, err = plugin.run(data=data, quiet=self.quiet)
            updates = {"rc": returncode, "out": out, "err": err}

            # Extract category/subcategory from plugin path
            plugin_dir = os.path.split(plugin.__file__)[0]
            # This will be relative to magui plugins folder
            subcategory = plugin_dir.replace(
                os.path.join(os.path.dirname(__file__), "plugins", ""), ""
            )

            if subcategory:
                if len(os.path.normpath(subcategory).split(os.sep)) > 1:
                    category = os.path.normpath(subcategory).split(os.sep)[0]
                else:
                    category = subcategory
                    subcategory = ""
            else:
                category = ""

            mydata = {
                "plugin": plugin_name,
                "name": "magui: %s" % plugin_name,
                "id": hashlib.sha512(
                    plugin.__file__.replace(os.path.dirname(__file__), "").encode(
                        "UTF-8"
                    )
                ).hexdigest(),
                "description": plugin.help(),
                "long_name": plugin.help(),
                "result": updates,
                "time": time.time() - plugstart_time,
                "category": category,
                "subcategory": subcategory,
            }

            result.append(mydata)

        return result
