#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Description: Coverage tests for Risu plugins
#
# Copyright (C) 2024 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

import os
import sys
import tempfile
import shutil
from unittest import TestCase
from collections import defaultdict

sys.path.append(os.path.abspath(os.path.dirname(__file__) + "/" + "../"))

try:
    import risuclient.shell as risu
except:
    import shell as risu


class CoverageTest(TestCase):
    def setUp(self):
        """Set up test environment"""
        self.tmpdir = tempfile.mkdtemp(prefix="risu-coverage-test-")
        self.plugins = risu.findplugins(
            folders=[os.path.join(risu.risudir, "plugins", "core")]
        )
        self.ansible_plugins = risu.findplugins(
            executables=False,
            fileextension=".yml",
            extension="ansible",
            folders=[os.path.join(risu.risudir, "plugins", "ansible")],
        )

    def tearDown(self):
        """Clean up test environment"""
        if os.path.exists(self.tmpdir):
            shutil.rmtree(self.tmpdir)

    def test_plugin_category_coverage(self):
        """Test coverage of different plugin categories"""
        categories = defaultdict(int)

        for plugin in self.plugins:
            plugin_path = plugin["plugin"]
            parts = plugin_path.split("/")
            if "plugins" in parts:
                plugin_index = parts.index("plugins")
                if plugin_index + 2 < len(parts):
                    category = parts[plugin_index + 2]
                    categories[category] += 1

        print("\nPlugin category coverage:")
        total_plugins = sum(categories.values())
        for category, count in sorted(categories.items()):
            percentage = (count / total_plugins) * 100
            print(f"  {category}: {count} plugins ({percentage:.1f}%)")

        # Ensure we have plugins in key categories
        self.assertGreater(categories["openstack"], 0, "Should have OpenStack plugins")
        self.assertGreater(categories["system"], 0, "Should have system plugins")
        self.assertGreater(categories["network"], 0, "Should have network plugins")

    def test_plugin_execution_coverage(self):
        """Test that plugins execute without errors"""
        successful_runs = 0
        failed_runs = 0
        error_categories = defaultdict(int)

        for plugin in self.plugins[:200]:  # Test subset to avoid timeout
            try:
                _ = risu.doplugin(plugin=plugin, path=self.tmpdir, options={})
                successful_runs += 1
            except Exception as e:
                failed_runs += 1
                # Categorize errors
                error_type = type(e).__name__
                error_categories[error_type] += 1

        total_tested = successful_runs + failed_runs
        success_rate = (successful_runs / total_tested) * 100 if total_tested > 0 else 0

        print("\nPlugin execution coverage:")
        print(f"  Total tested: {total_tested}")
        print(f"  Successful: {successful_runs} ({success_rate:.1f}%)")
        print(f"  Failed: {failed_runs}")

        if error_categories:
            print("  Error types:")
            for error_type, count in error_categories.items():
                print(f"    {error_type}: {count}")

        # Assert minimum success rate
        self.assertGreaterEqual(
            success_rate, 70, f"Plugin success rate too low: {success_rate:.1f}%"
        )

    def test_ansible_plugin_coverage(self):
        """Test coverage of Ansible plugins"""
        ansible_categories = defaultdict(int)

        for plugin in self.ansible_plugins:
            plugin_path = plugin["plugin"]
            parts = plugin_path.split("/")
            if "plugins" in parts:
                plugin_index = parts.index("plugins")
                if plugin_index + 2 < len(parts):
                    category = parts[plugin_index + 2]
                    ansible_categories[category] += 1

        print("\nAnsible plugin coverage:")
        total_ansible = sum(ansible_categories.values())
        for category, count in sorted(ansible_categories.items()):
            percentage = (count / total_ansible) * 100 if total_ansible > 0 else 0
            print(f"  {category}: {count} plugins ({percentage:.1f}%)")

        # Ensure we have some Ansible plugins
        self.assertGreater(
            total_ansible, 0, "Should have at least some Ansible plugins"
        )

    def test_plugin_metadata_coverage(self):
        """Test coverage of plugin metadata fields"""
        metadata_stats = {
            "has_description": 0,
            "has_long_name": 0,
            "has_priority": 0,
            "has_kb": 0,
            "has_bugzilla": 0,
            "total": 0,
        }

        for plugin in self.plugins:
            metadata_stats["total"] += 1

            if plugin.get("description"):
                metadata_stats["has_description"] += 1
            if plugin.get("long_name"):
                metadata_stats["has_long_name"] += 1
            if plugin.get("priority"):
                metadata_stats["has_priority"] += 1
            if plugin.get("kb"):
                metadata_stats["has_kb"] += 1
            if plugin.get("bugzilla"):
                metadata_stats["has_bugzilla"] += 1

        print("\nPlugin metadata coverage:")
        total = metadata_stats["total"]
        for field, count in metadata_stats.items():
            if field != "total":
                percentage = (count / total) * 100 if total > 0 else 0
                print(f"  {field}: {count}/{total} ({percentage:.1f}%)")

        # Assert minimum metadata coverage
        desc_coverage = (metadata_stats["has_description"] / total) * 100
        name_coverage = (metadata_stats["has_long_name"] / total) * 100

        self.assertGreaterEqual(
            desc_coverage, 95, f"Description coverage too low: {desc_coverage:.1f}%"
        )
        self.assertGreaterEqual(
            name_coverage, 95, f"Long name coverage too low: {name_coverage:.1f}%"
        )

    def test_plugin_priority_distribution(self):
        """Test distribution of plugin priorities"""
        priority_ranges = {
            "critical (900-999)": 0,
            "high (800-899)": 0,
            "medium (600-799)": 0,
            "medium-low (400-599)": 0,
            "low (200-399)": 0,
            "very_low (100-199)": 0,
            "lowest (1-99)": 0,
            "no_priority": 0,
        }

        for plugin in self.plugins:
            priority = plugin.get("priority")
            if priority:
                try:
                    prio_val = int(priority)
                    if 900 <= prio_val <= 999:
                        priority_ranges["critical (900-999)"] += 1
                    elif 800 <= prio_val <= 899:
                        priority_ranges["high (800-899)"] += 1
                    elif 600 <= prio_val <= 799:
                        priority_ranges["medium (600-799)"] += 1
                    elif 400 <= prio_val <= 599:
                        priority_ranges["medium-low (400-599)"] += 1
                    elif 200 <= prio_val <= 399:
                        priority_ranges["low (200-399)"] += 1
                    elif 100 <= prio_val <= 199:
                        priority_ranges["very_low (100-199)"] += 1
                    elif 1 <= prio_val <= 99:
                        priority_ranges["lowest (1-99)"] += 1
                except ValueError:
                    priority_ranges["no_priority"] += 1
            else:
                priority_ranges["no_priority"] += 1

        print("\nPlugin priority distribution:")
        total = len(self.plugins)
        for range_name, count in priority_ranges.items():
            percentage = (count / total) * 100 if total > 0 else 0
            print(f"  {range_name}: {count} ({percentage:.1f}%)")

        # Assert that most plugins have priorities
        no_priority_pct = (priority_ranges["no_priority"] / total) * 100
        self.assertLessEqual(
            no_priority_pct,
            5,
            f"Too many plugins without priority: {no_priority_pct:.1f}%",
        )

    def test_plugin_file_structure_coverage(self):
        """Test coverage of plugin file structure"""
        file_types = defaultdict(int)

        for plugin in self.plugins:
            plugin_path = plugin["plugin"]
            if plugin_path.endswith(".sh"):
                file_types["shell"] += 1
            elif plugin_path.endswith(".py"):
                file_types["python"] += 1
            elif plugin_path.endswith(".yml") or plugin_path.endswith(".yaml"):
                file_types["ansible"] += 1
            else:
                file_types["other"] += 1

        print("\nPlugin file type coverage:")
        total = sum(file_types.values())
        for file_type, count in sorted(file_types.items()):
            percentage = (count / total) * 100 if total > 0 else 0
            print(f"  {file_type}: {count} ({percentage:.1f}%)")

        # Assert that we have both shell and python plugins
        self.assertGreater(file_types["shell"], 0, "Should have shell plugins")
        self.assertGreater(file_types["python"], 0, "Should have Python plugins")
