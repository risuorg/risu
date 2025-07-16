#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Description: OpenShift plugin specific tests
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

sys.path.append(os.path.abspath(os.path.dirname(__file__) + "/" + "../"))

try:
    import risuclient.shell as risu
except:
    import shell as risu


class OpenShiftPluginTest(TestCase):
    def setUp(self):
        """Set up test environment"""
        self.tmpdir = tempfile.mkdtemp(prefix="risu-openshift-test-")
        self.openshift_plugins = risu.findplugins(
            folders=[os.path.join(risu.risudir, "plugins", "core", "openshift")]
        )

    def tearDown(self):
        """Clean up test environment"""
        if os.path.exists(self.tmpdir):
            shutil.rmtree(self.tmpdir)

    def test_openshift_plugins_exist(self):
        """Test that OpenShift plugins exist and are categorized correctly"""
        categories = {}

        for plugin in self.openshift_plugins:
            plugin_path = plugin["plugin"]
            parts = plugin_path.split("/")
            if "openshift" in parts:
                openshift_index = parts.index("openshift")
                if openshift_index + 1 < len(parts):
                    category = parts[openshift_index + 1]
                    if category not in categories:
                        categories[category] = 0
                    categories[category] += 1

        print("\nOpenShift plugin categories:")
        for category, count in sorted(categories.items()):
            print(f"  {category}: {count} plugins")

        # Assert we have some OpenShift plugins
        self.assertGreater(
            len(self.openshift_plugins), 0, "Should have OpenShift plugins"
        )

    def test_etcd_plugins(self):
        """Test etcd-specific plugins"""
        etcd_plugins = [p for p in self.openshift_plugins if "etcd" in p["plugin"]]

        if etcd_plugins:  # Only test if etcd plugins exist
            for plugin in etcd_plugins:
                priority = plugin.get("priority")
                if priority:
                    try:
                        prio_val = int(priority)
                        # etcd is critical for OpenShift, should have high priority
                        self.assertGreaterEqual(
                            prio_val,
                            700,
                            f"etcd plugin {plugin['plugin']} should have high priority",
                        )
                    except ValueError:
                        self.fail(
                            f"etcd plugin {plugin['plugin']} has invalid priority: {priority}"
                        )

    def test_master_api_plugins(self):
        """Test master API-specific plugins"""
        api_plugins = [p for p in self.openshift_plugins if "master-api" in p["plugin"]]

        if api_plugins:  # Only test if master API plugins exist
            for plugin in api_plugins:
                priority = plugin.get("priority")
                if priority:
                    try:
                        prio_val = int(priority)
                        # Master API is critical, should have very high priority
                        self.assertGreaterEqual(
                            prio_val,
                            800,
                            f"Master API plugin {plugin['plugin']} should have very high priority",
                        )
                    except ValueError:
                        self.fail(
                            f"Master API plugin {plugin['plugin']} has invalid priority: {priority}"
                        )

    def test_node_plugins(self):
        """Test node-specific plugins"""
        node_plugins = [p for p in self.openshift_plugins if "node" in p["plugin"]]

        if node_plugins:  # Only test if node plugins exist
            for plugin in node_plugins:
                priority = plugin.get("priority")
                if priority:
                    try:
                        prio_val = int(priority)
                        # Node health is important, should have high priority
                        self.assertGreaterEqual(
                            prio_val,
                            700,
                            f"Node plugin {plugin['plugin']} should have high priority",
                        )
                    except ValueError:
                        self.fail(
                            f"Node plugin {plugin['plugin']} has invalid priority: {priority}"
                        )

    def test_cluster_plugins(self):
        """Test cluster-specific plugins"""
        cluster_plugins = [
            p for p in self.openshift_plugins if "cluster" in p["plugin"]
        ]

        if cluster_plugins:  # Only test if cluster plugins exist
            for plugin in cluster_plugins:
                priority = plugin.get("priority")
                if priority:
                    try:
                        prio_val = int(priority)
                        # Cluster health is critical, should have high priority
                        self.assertGreaterEqual(
                            prio_val,
                            800,
                            f"Cluster plugin {plugin['plugin']} should have high priority",
                        )
                    except ValueError:
                        self.fail(
                            f"Cluster plugin {plugin['plugin']} has invalid priority: {priority}"
                        )

    def test_docker_plugins(self):
        """Test Docker-specific plugins in OpenShift context"""
        docker_plugins = [p for p in self.openshift_plugins if "docker" in p["plugin"]]

        if docker_plugins:  # Only test if Docker plugins exist
            for plugin in docker_plugins:
                priority = plugin.get("priority")
                if priority:
                    try:
                        prio_val = int(priority)
                        # Docker is important for OpenShift, should have medium-high priority
                        self.assertGreaterEqual(
                            prio_val,
                            600,
                            f"Docker plugin {plugin['plugin']} should have medium-high priority",
                        )
                    except ValueError:
                        self.fail(
                            f"Docker plugin {plugin['plugin']} has invalid priority: {priority}"
                        )

    def test_openshift_plugin_metadata(self):
        """Test that OpenShift plugins have proper metadata"""
        for plugin in self.openshift_plugins:
            # All OpenShift plugins should have description
            self.assertIsNotNone(
                plugin.get("description"),
                f"OpenShift plugin {plugin['plugin']} should have description",
            )
            self.assertNotEqual(
                plugin.get("description", "").strip(),
                "",
                f"OpenShift plugin {plugin['plugin']} should have non-empty description",
            )

            # All OpenShift plugins should have long_name
            self.assertIsNotNone(
                plugin.get("long_name"),
                f"OpenShift plugin {plugin['plugin']} should have long_name",
            )
            self.assertNotEqual(
                plugin.get("long_name", "").strip(),
                "",
                f"OpenShift plugin {plugin['plugin']} should have non-empty long_name",
            )

            # All OpenShift plugins should have priority
            self.assertIsNotNone(
                plugin.get("priority"),
                f"OpenShift plugin {plugin['plugin']} should have priority",
            )

            # Priority should be valid integer
            priority = plugin.get("priority")
            if priority:
                try:
                    prio_val = int(priority)
                    self.assertGreaterEqual(
                        prio_val,
                        1,
                        f"OpenShift plugin {plugin['plugin']} priority should be >= 1",
                    )
                    self.assertLessEqual(
                        prio_val,
                        999,
                        f"OpenShift plugin {plugin['plugin']} priority should be <= 999",
                    )
                except ValueError:
                    self.fail(
                        f"OpenShift plugin {plugin['plugin']} has invalid priority: {priority}"
                    )

    def test_openshift_plugin_execution(self):
        """Test execution of OpenShift plugins"""
        successful_runs = 0
        failed_runs = 0

        # Test all OpenShift plugins (usually smaller number than OpenStack)
        for plugin in self.openshift_plugins:
            try:
                _ = risu.doplugin(plugin=plugin, path=self.tmpdir, options={})
                successful_runs += 1
            except Exception as e:
                failed_runs += 1
                print(f"Error running OpenShift plugin {plugin['plugin']}: {e}")

        total_tested = successful_runs + failed_runs
        success_rate = (successful_runs / total_tested) * 100 if total_tested > 0 else 0

        print("\nOpenShift plugin execution results:")
        print(f"  Total tested: {total_tested}")
        print(f"  Successful: {successful_runs} ({success_rate:.1f}%)")
        print(f"  Failed: {failed_runs}")

        # Assert minimum success rate for OpenShift plugins
        if total_tested > 0:
            self.assertGreaterEqual(
                success_rate,
                60,
                f"OpenShift plugin success rate too low: {success_rate:.1f}%",
            )

    def test_openshift_plugin_priority_distribution(self):
        """Test priority distribution for OpenShift plugins"""
        priority_counts = {}

        for plugin in self.openshift_plugins:
            priority = plugin.get("priority")
            if priority:
                try:
                    prio_val = int(priority)
                    prio_range = (
                        f"{(prio_val // 100) * 100}-{(prio_val // 100) * 100 + 99}"
                    )
                    if prio_range not in priority_counts:
                        priority_counts[prio_range] = 0
                    priority_counts[prio_range] += 1
                except ValueError:
                    pass

        print("\nOpenShift plugin priority distribution:")
        for prio_range, count in sorted(priority_counts.items()):
            print(f"  {prio_range}: {count} plugins")

        # OpenShift plugins should generally have medium to high priority
        high_priority = (
            priority_counts.get("700-799", 0)
            + priority_counts.get("800-899", 0)
            + priority_counts.get("900-999", 0)
        )
        total_with_priority = sum(priority_counts.values())

        if total_with_priority > 0:
            high_percentage = (high_priority / total_with_priority) * 100
            self.assertGreaterEqual(
                high_percentage,
                50,
                f"Expected more high priority OpenShift plugins: {high_percentage:.1f}%",
            )

    def test_python_openshift_plugins(self):
        """Test Python-based OpenShift plugins"""
        python_plugins = [
            p for p in self.openshift_plugins if p["plugin"].endswith(".py")
        ]

        if python_plugins:  # Only test if Python plugins exist
            print(f"\nPython OpenShift plugins found: {len(python_plugins)}")
            for plugin in python_plugins:
                # Test that Python plugins have proper metadata
                self.assertIsNotNone(
                    plugin.get("description"),
                    f"Python OpenShift plugin {plugin['plugin']} should have description",
                )
                self.assertIsNotNone(
                    plugin.get("long_name"),
                    f"Python OpenShift plugin {plugin['plugin']} should have long_name",
                )

    def test_shell_openshift_plugins(self):
        """Test shell-based OpenShift plugins"""
        shell_plugins = [
            p for p in self.openshift_plugins if p["plugin"].endswith(".sh")
        ]

        if shell_plugins:  # Only test if shell plugins exist
            print(f"\nShell OpenShift plugins found: {len(shell_plugins)}")
            for plugin in shell_plugins:
                # Test that shell plugins have proper metadata
                self.assertIsNotNone(
                    plugin.get("description"),
                    f"Shell OpenShift plugin {plugin['plugin']} should have description",
                )
                self.assertIsNotNone(
                    plugin.get("long_name"),
                    f"Shell OpenShift plugin {plugin['plugin']} should have long_name",
                )

    def test_openshift_plugin_categories(self):
        """Test categorization of OpenShift plugins"""
        expected_categories = ["etcd", "master-api", "node", "cluster", "docker"]
        found_categories = set()

        for plugin in self.openshift_plugins:
            plugin_path = plugin["plugin"]
            for category in expected_categories:
                if category in plugin_path:
                    found_categories.add(category)
                    break

        print(f"\nOpenShift plugin categories found: {found_categories}")

        # We should have at least some of the expected categories
        self.assertGreater(
            len(found_categories),
            0,
            "Should have plugins in at least one expected category",
        )

    def test_openshift_plugin_consistency(self):
        """Test consistency of OpenShift plugin metadata"""
        inconsistent_plugins = []

        for plugin in self.openshift_plugins:
            issues = []

            # Check description consistency
            description = plugin.get("description", "")
            if (
                "openshift" not in description.lower()
                and "ocp" not in description.lower()
            ):
                issues.append("Description doesn't mention OpenShift/OCP")

            # Check long_name consistency
            long_name = plugin.get("long_name", "")
            if "openshift" not in long_name.lower() and "ocp" not in long_name.lower():
                issues.append("Long name doesn't mention OpenShift/OCP")

            if issues:
                inconsistent_plugins.append((plugin["plugin"], issues))

        if inconsistent_plugins:
            print("\nInconsistent OpenShift plugins:")
            for plugin_name, issues in inconsistent_plugins:
                print(f"  {plugin_name}: {', '.join(issues)}")

        # Allow some inconsistency but not too much
        inconsistency_rate = (
            len(inconsistent_plugins) / len(self.openshift_plugins) * 100
        )
        self.assertLessEqual(
            inconsistency_rate,
            30,
            f"Too many inconsistent OpenShift plugins: {inconsistency_rate:.1f}%",
        )
