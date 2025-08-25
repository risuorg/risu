#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Description: Network plugin specific tests
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


class NetworkPluginTest(TestCase):
    def setUp(self):
        """Set up test environment"""
        self.tmpdir = tempfile.mkdtemp(prefix="risu-network-test-")
        self.network_plugins = risu.findplugins(
            folders=[os.path.join(risu.risudir, "plugins", "core", "network")]
        )
        # Also check for network plugins in OpenStack
        self.openstack_network_plugins = risu.findplugins(
            folders=[
                os.path.join(risu.risudir, "plugins", "core", "openstack", "network")
            ]
        )

    def tearDown(self):
        """Clean up test environment"""
        if os.path.exists(self.tmpdir):
            shutil.rmtree(self.tmpdir)

    def test_network_plugins_exist(self):
        """Test that network plugins exist"""
        all_network_plugins = self.network_plugins + self.openstack_network_plugins

        self.assertGreater(len(all_network_plugins), 0, "Should have network plugins")

        print("\nNetwork plugins found:")
        print(f"  Core network plugins: {len(self.network_plugins)}")
        print(f"  OpenStack network plugins: {len(self.openstack_network_plugins)}")
        print(f"  Total: {len(all_network_plugins)}")

    def test_interface_plugins(self):
        """Test interface-related plugins"""
        interface_plugins = [
            p for p in self.network_plugins if "interface" in p["plugin"]
        ]

        if interface_plugins:  # Only test if interface plugins exist
            for plugin in interface_plugins:
                priority = plugin.get("priority")
                if priority:
                    try:
                        prio_val = int(priority)
                        # Interface issues can cause connectivity problems, should have high priority
                        self.assertGreaterEqual(
                            prio_val,
                            700,
                            f"Interface plugin {plugin['plugin']} should have high priority",
                        )
                    except ValueError:
                        self.fail(
                            f"Interface plugin {plugin['plugin']} has invalid priority: {priority}"
                        )

    def test_external_connectivity_plugins(self):
        """Test external connectivity plugins"""
        connectivity_plugins = [
            p for p in self.network_plugins if "external_connectivity" in p["plugin"]
        ]

        if connectivity_plugins:  # Only test if connectivity plugins exist
            for plugin in connectivity_plugins:
                priority = plugin.get("priority")
                if priority:
                    try:
                        prio_val = int(priority)
                        # External connectivity is critical, should have very high priority
                        self.assertGreaterEqual(
                            prio_val,
                            900,
                            f"Connectivity plugin {plugin['plugin']} should have very high priority",
                        )
                    except ValueError:
                        self.fail(
                            f"Connectivity plugin {plugin['plugin']} has invalid priority: {priority}"
                        )

    def test_openstack_network_plugins(self):
        """Test OpenStack network-specific plugins"""
        if self.openstack_network_plugins:
            for plugin in self.openstack_network_plugins:
                priority = plugin.get("priority")
                if priority:
                    try:
                        prio_val = int(priority)
                        # OpenStack network issues should have high priority
                        self.assertGreaterEqual(
                            prio_val,
                            700,
                            f"OpenStack network plugin {plugin['plugin']} should have high priority",
                        )
                    except ValueError:
                        self.fail(
                            f"OpenStack network plugin {plugin['plugin']} has invalid priority: {priority}"
                        )

    def test_network_plugin_metadata(self):
        """Test that network plugins have proper metadata"""
        all_network_plugins = self.network_plugins + self.openstack_network_plugins

        for plugin in all_network_plugins:
            # All network plugins should have description
            self.assertIsNotNone(
                plugin.get("description"),
                f"Network plugin {plugin['plugin']} should have description",
            )
            self.assertNotEqual(
                plugin.get("description", "").strip(),
                "",
                f"Network plugin {plugin['plugin']} should have non-empty description",
            )

            # All network plugins should have long_name
            self.assertIsNotNone(
                plugin.get("long_name"),
                f"Network plugin {plugin['plugin']} should have long_name",
            )
            self.assertNotEqual(
                plugin.get("long_name", "").strip(),
                "",
                f"Network plugin {plugin['plugin']} should have non-empty long_name",
            )

            # All network plugins should have priority
            self.assertIsNotNone(
                plugin.get("priority"),
                f"Network plugin {plugin['plugin']} should have priority",
            )

            # Priority should be valid integer
            priority = plugin.get("priority")
            if priority:
                try:
                    prio_val = int(priority)
                    self.assertGreaterEqual(
                        prio_val,
                        1,
                        f"Network plugin {plugin['plugin']} priority should be >= 1",
                    )
                    self.assertLessEqual(
                        prio_val,
                        999,
                        f"Network plugin {plugin['plugin']} priority should be <= 999",
                    )
                except ValueError:
                    self.fail(
                        f"Network plugin {plugin['plugin']} has invalid priority: {priority}"
                    )

    def test_network_plugin_execution(self):
        """Test execution of network plugins"""
        all_network_plugins = self.network_plugins + self.openstack_network_plugins
        successful_runs = 0
        failed_runs = 0

        # Test all network plugins
        for plugin in all_network_plugins:
            try:
                _ = risu.doplugin(plugin=plugin, path=self.tmpdir, options={})
                successful_runs += 1
            except Exception as e:
                failed_runs += 1
                print(f"Error running network plugin {plugin['plugin']}: {e}")

        total_tested = successful_runs + failed_runs
        success_rate = (successful_runs / total_tested) * 100 if total_tested > 0 else 0

        print("\nNetwork plugin execution results:")
        print(f"  Total tested: {total_tested}")
        print(f"  Successful: {successful_runs} ({success_rate:.1f}%)")
        print(f"  Failed: {failed_runs}")

        # Assert minimum success rate for network plugins
        if total_tested > 0:
            self.assertGreaterEqual(
                success_rate,
                60,
                f"Network plugin success rate too low: {success_rate:.1f}%",
            )

    def test_network_plugin_priority_distribution(self):
        """Test priority distribution for network plugins"""
        all_network_plugins = self.network_plugins + self.openstack_network_plugins
        priority_counts = {}

        for plugin in all_network_plugins:
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

        print("\nNetwork plugin priority distribution:")
        for prio_range, count in sorted(priority_counts.items()):
            print(f"  {prio_range}: {count} plugins")

        # Network plugins should generally have high priority
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
                f"Expected more high priority network plugins: {high_percentage:.1f}%",
            )

    def test_network_plugin_consistency(self):
        """Test consistency of network plugin metadata"""
        all_network_plugins = self.network_plugins + self.openstack_network_plugins
        inconsistent_plugins = []

        for plugin in all_network_plugins:
            issues = []

            # Check description consistency
            description = plugin.get("description", "")
            if not any(
                keyword in description.lower()
                for keyword in [
                    "network",
                    "interface",
                    "connectivity",
                    "ip",
                    "route",
                    "dns",
                ]
            ):
                issues.append("Description doesn't mention network-related keywords")

            # Check long_name consistency
            long_name = plugin.get("long_name", "")
            if not any(
                keyword in long_name.lower()
                for keyword in [
                    "network",
                    "interface",
                    "connectivity",
                    "ip",
                    "route",
                    "dns",
                ]
            ):
                issues.append("Long name doesn't mention network-related keywords")

            if issues:
                inconsistent_plugins.append((plugin["plugin"], issues))

        if inconsistent_plugins:
            print("\nInconsistent network plugins:")
            for plugin_name, issues in inconsistent_plugins:
                print(f"  {plugin_name}: {', '.join(issues)}")

        # Allow some inconsistency but not too much
        inconsistency_rate = len(inconsistent_plugins) / len(all_network_plugins) * 100
        self.assertLessEqual(
            inconsistency_rate,
            25,
            f"Too many inconsistent network plugins: {inconsistency_rate:.1f}%",
        )

    def test_network_plugin_types(self):
        """Test coverage of different network plugin types"""
        all_network_plugins = self.network_plugins + self.openstack_network_plugins

        network_types = {
            "interface": ["interface", "eth", "bond"],
            "connectivity": ["connectivity", "ping", "external"],
            "routing": ["route", "routing", "gateway"],
            "dns": ["dns", "resolve", "nameserver"],
            "firewall": ["firewall", "iptables", "netfilter"],
            "openstack_network": ["neutron", "openvswitch", "ovs"],
        }

        found_types = {}

        for net_type, keywords in network_types.items():
            found_types[net_type] = []
            for plugin in all_network_plugins:
                plugin_path = plugin["plugin"].lower()
                plugin_desc = plugin.get("description", "").lower()

                for keyword in keywords:
                    if keyword in plugin_path or keyword in plugin_desc:
                        found_types[net_type].append(plugin["plugin"])
                        break

        print("\nNetwork plugin type coverage:")
        for net_type, plugins in found_types.items():
            print(f"  {net_type}: {len(plugins)} plugins")

        # Should have coverage for interface and connectivity at least
        self.assertGreater(
            len(found_types["interface"]), 0, "Should have plugins for interface issues"
        )
        self.assertGreater(
            len(found_types["connectivity"]),
            0,
            "Should have plugins for connectivity issues",
        )

    def test_network_plugin_shell_vs_python(self):
        """Test distribution of shell vs Python network plugins"""
        all_network_plugins = self.network_plugins + self.openstack_network_plugins

        shell_plugins = [p for p in all_network_plugins if p["plugin"].endswith(".sh")]
        python_plugins = [p for p in all_network_plugins if p["plugin"].endswith(".py")]

        print("\nNetwork plugin implementation distribution:")
        print(f"  Shell plugins: {len(shell_plugins)}")
        print(f"  Python plugins: {len(python_plugins)}")

        # Should have at least some shell plugins for network checks
        if len(all_network_plugins) > 0:
            self.assertGreater(
                len(shell_plugins), 0, "Should have shell network plugins"
            )

    def test_network_plugin_error_handling(self):
        """Test error handling in network plugins"""
        all_network_plugins = self.network_plugins + self.openstack_network_plugins

        # Test with a non-existent directory to see how plugins handle missing data
        error_tmpdir = tempfile.mkdtemp(prefix="risu-network-error-test-")
        try:
            # Create an empty directory structure
            os.makedirs(os.path.join(error_tmpdir, "etc"), exist_ok=True)

            error_count = 0
            exception_types = {}

            for plugin in all_network_plugins[:10]:  # Test subset
                try:
                    result = risu.doplugin(plugin=plugin, path=error_tmpdir, options={})
                    # Plugin should handle missing data gracefully
                    if result and "result" in result:
                        rc = result["result"].get("rc", 0)
                        # Should return appropriate return code (not crash)
                        self.assertIn(
                            rc,
                            [
                                risu.RC_OKAY,
                                risu.RC_FAILED,
                                risu.RC_SKIPPED,
                                risu.RC_INFO,
                            ],
                            f"Plugin {plugin['plugin']} returned invalid return code: {rc}",
                        )
                except Exception as e:
                    error_count += 1
                    exception_type = type(e).__name__
                    exception_types[exception_type] = (
                        exception_types.get(exception_type, 0) + 1
                    )

            print("\nNetwork plugin error handling:")
            print(
                f"  Plugins with errors: {error_count}/{min(10, len(all_network_plugins))}"
            )

            if exception_types:
                print("  Exception types:")
                for exc_type, count in exception_types.items():
                    print(f"    {exc_type}: {count}")

            # Most plugins should handle errors gracefully
            if len(all_network_plugins) > 0:
                error_rate = (error_count / min(10, len(all_network_plugins))) * 100
                self.assertLessEqual(
                    error_rate,
                    60,
                    f"Too many network plugins with errors: {error_rate:.1f}%",
                )

        finally:
            shutil.rmtree(error_tmpdir)
