#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Description: Security plugin specific tests
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


class SecurityPluginTest(TestCase):
    def setUp(self):
        """Set up test environment"""
        self.tmpdir = tempfile.mkdtemp(prefix="risu-security-test-")
        self.security_plugins = risu.findplugins(
            folders=[os.path.join(risu.risudir, "plugins", "core", "security")]
        )

    def tearDown(self):
        """Clean up test environment"""
        if os.path.exists(self.tmpdir):
            shutil.rmtree(self.tmpdir)

    def test_security_plugins_exist(self):
        """Test that security plugins exist and are categorized correctly"""
        categories = {}

        for plugin in self.security_plugins:
            plugin_path = plugin["plugin"]
            parts = plugin_path.split("/")
            if "security" in parts:
                security_index = parts.index("security")
                if security_index + 1 < len(parts):
                    category = parts[security_index + 1]
                    if category not in categories:
                        categories[category] = 0
                    categories[category] += 1

        print("\nSecurity plugin categories:")
        for category, count in sorted(categories.items()):
            print(f"  {category}: {count} plugins")

        # Assert we have some security plugins
        self.assertGreater(
            len(self.security_plugins), 0, "Should have security plugins"
        )

    def test_meltdown_plugins(self):
        """Test Meltdown-specific security plugins"""
        meltdown_plugins = [
            p for p in self.security_plugins if "meltdown" in p["plugin"]
        ]

        if meltdown_plugins:  # Only test if Meltdown plugins exist
            for plugin in meltdown_plugins:
                priority = plugin.get("priority")
                if priority:
                    try:
                        prio_val = int(priority)
                        # Meltdown is critical security issue, should have high priority
                        self.assertGreaterEqual(
                            prio_val,
                            800,
                            f"Meltdown plugin {plugin['plugin']} should have high priority",
                        )
                    except ValueError:
                        self.fail(
                            f"Meltdown plugin {plugin['plugin']} has invalid priority: {priority}"
                        )

                # Check that Meltdown plugins have proper metadata
                self.assertIsNotNone(
                    plugin.get("description"),
                    f"Meltdown plugin {plugin['plugin']} should have description",
                )
                self.assertIn(
                    "meltdown",
                    plugin.get("description", "").lower(),
                    f"Meltdown plugin {plugin['plugin']} description should mention meltdown",
                )

    def test_spectre_plugins(self):
        """Test Spectre-specific security plugins"""
        spectre_plugins = [p for p in self.security_plugins if "spectre" in p["plugin"]]

        if spectre_plugins:  # Only test if Spectre plugins exist
            for plugin in spectre_plugins:
                priority = plugin.get("priority")
                if priority:
                    try:
                        prio_val = int(priority)
                        # Spectre is critical security issue, should have high priority
                        self.assertGreaterEqual(
                            prio_val,
                            800,
                            f"Spectre plugin {plugin['plugin']} should have high priority",
                        )
                    except ValueError:
                        self.fail(
                            f"Spectre plugin {plugin['plugin']} has invalid priority: {priority}"
                        )

                # Check that Spectre plugins have proper metadata
                self.assertIsNotNone(
                    plugin.get("description"),
                    f"Spectre plugin {plugin['plugin']} should have description",
                )
                self.assertIn(
                    "spectre",
                    plugin.get("description", "").lower(),
                    f"Spectre plugin {plugin['plugin']} description should mention spectre",
                )

    def test_speculative_store_bypass_plugins(self):
        """Test Speculative Store Bypass security plugins"""
        ssb_plugins = [
            p
            for p in self.security_plugins
            if "speculative-store-bypass" in p["plugin"]
        ]

        if ssb_plugins:  # Only test if SSB plugins exist
            for plugin in ssb_plugins:
                priority = plugin.get("priority")
                if priority:
                    try:
                        prio_val = int(priority)
                        # SSB is critical security issue, should have high priority
                        self.assertGreaterEqual(
                            prio_val,
                            800,
                            f"SSB plugin {plugin['plugin']} should have high priority",
                        )
                    except ValueError:
                        self.fail(
                            f"SSB plugin {plugin['plugin']} has invalid priority: {priority}"
                        )

    def test_dhcp_security_plugins(self):
        """Test DHCP-related security plugins"""
        dhcp_plugins = [p for p in self.security_plugins if "dhcp" in p["plugin"]]

        if dhcp_plugins:  # Only test if DHCP plugins exist
            for plugin in dhcp_plugins:
                priority = plugin.get("priority")
                if priority:
                    try:
                        prio_val = int(priority)
                        # DHCP security issues should have high priority
                        self.assertGreaterEqual(
                            prio_val,
                            700,
                            f"DHCP plugin {plugin['plugin']} should have high priority",
                        )
                    except ValueError:
                        self.fail(
                            f"DHCP plugin {plugin['plugin']} has invalid priority: {priority}"
                        )

    def test_security_plugin_metadata(self):
        """Test that security plugins have proper metadata"""
        for plugin in self.security_plugins:
            # All security plugins should have description
            self.assertIsNotNone(
                plugin.get("description"),
                f"Security plugin {plugin['plugin']} should have description",
            )
            self.assertNotEqual(
                plugin.get("description", "").strip(),
                "",
                f"Security plugin {plugin['plugin']} should have non-empty description",
            )

            # All security plugins should have long_name
            self.assertIsNotNone(
                plugin.get("long_name"),
                f"Security plugin {plugin['plugin']} should have long_name",
            )
            self.assertNotEqual(
                plugin.get("long_name", "").strip(),
                "",
                f"Security plugin {plugin['plugin']} should have non-empty long_name",
            )

            # All security plugins should have priority
            self.assertIsNotNone(
                plugin.get("priority"),
                f"Security plugin {plugin['plugin']} should have priority",
            )

            # Priority should be valid integer
            priority = plugin.get("priority")
            if priority:
                try:
                    prio_val = int(priority)
                    self.assertGreaterEqual(
                        prio_val,
                        1,
                        f"Security plugin {plugin['plugin']} priority should be >= 1",
                    )
                    self.assertLessEqual(
                        prio_val,
                        999,
                        f"Security plugin {plugin['plugin']} priority should be <= 999",
                    )
                except ValueError:
                    self.fail(
                        f"Security plugin {plugin['plugin']} has invalid priority: {priority}"
                    )

    def test_security_plugin_execution(self):
        """Test execution of security plugins"""
        successful_runs = 0
        failed_runs = 0

        # Test all security plugins
        for plugin in self.security_plugins:
            try:
                _ = risu.doplugin(plugin=plugin, path=self.tmpdir, options={})
                successful_runs += 1
            except Exception as e:
                failed_runs += 1
                print(f"Error running security plugin {plugin['plugin']}: {e}")

        total_tested = successful_runs + failed_runs
        success_rate = (successful_runs / total_tested) * 100 if total_tested > 0 else 0

        print("\nSecurity plugin execution results:")
        print(f"  Total tested: {total_tested}")
        print(f"  Successful: {successful_runs} ({success_rate:.1f}%)")
        print(f"  Failed: {failed_runs}")

        # Assert minimum success rate for security plugins
        if total_tested > 0:
            self.assertGreaterEqual(
                success_rate,
                60,
                f"Security plugin success rate too low: {success_rate:.1f}%",
            )

    def test_security_plugin_priority_distribution(self):
        """Test priority distribution for security plugins"""
        priority_counts = {}

        for plugin in self.security_plugins:
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

        print("\nSecurity plugin priority distribution:")
        for prio_range, count in sorted(priority_counts.items()):
            print(f"  {prio_range}: {count} plugins")

        # Security plugins should generally have high to very high priority
        high_priority = priority_counts.get("800-899", 0) + priority_counts.get(
            "900-999", 0
        )
        total_with_priority = sum(priority_counts.values())

        if total_with_priority > 0:
            high_percentage = (high_priority / total_with_priority) * 100
            self.assertGreaterEqual(
                high_percentage,
                60,
                f"Expected more high priority security plugins: {high_percentage:.1f}%",
            )

    def test_security_vulnerability_types(self):
        """Test coverage of different security vulnerability types"""
        vulnerability_types = {
            "cpu_vulnerabilities": ["meltdown", "spectre", "speculative-store-bypass"],
            "network_vulnerabilities": ["dhcp"],
            "system_vulnerabilities": ["privilege", "escalation"],
        }

        found_vulnerabilities = {}

        for vuln_type, keywords in vulnerability_types.items():
            found_vulnerabilities[vuln_type] = []
            for plugin in self.security_plugins:
                plugin_path = plugin["plugin"].lower()
                plugin_desc = plugin.get("description", "").lower()

                for keyword in keywords:
                    if keyword in plugin_path or keyword in plugin_desc:
                        found_vulnerabilities[vuln_type].append(plugin["plugin"])
                        break

        print("\nSecurity vulnerability type coverage:")
        for vuln_type, plugins in found_vulnerabilities.items():
            print(f"  {vuln_type}: {len(plugins)} plugins")

        # Should have coverage for CPU vulnerabilities at least
        self.assertGreater(
            len(found_vulnerabilities["cpu_vulnerabilities"]),
            0,
            "Should have plugins for CPU vulnerabilities",
        )

    def test_security_plugin_consistency(self):
        """Test consistency of security plugin metadata"""
        inconsistent_plugins = []

        for plugin in self.security_plugins:
            issues = []

            # Check description consistency
            description = plugin.get("description", "")
            if not any(
                keyword in description.lower()
                for keyword in ["security", "vulnerability", "cve", "attack", "exploit"]
            ):
                issues.append("Description doesn't mention security-related keywords")

            # Check priority consistency - security plugins should have high priority
            priority = plugin.get("priority")
            if priority:
                try:
                    prio_val = int(priority)
                    if prio_val < 600:  # Below medium priority
                        issues.append(
                            f"Priority too low for security plugin: {prio_val}"
                        )
                except ValueError:
                    issues.append(f"Invalid priority: {priority}")

            if issues:
                inconsistent_plugins.append((plugin["plugin"], issues))

        if inconsistent_plugins:
            print("\nInconsistent security plugins:")
            for plugin_name, issues in inconsistent_plugins:
                print(f"  {plugin_name}: {', '.join(issues)}")

        # Allow some inconsistency but not too much
        inconsistency_rate = (
            len(inconsistent_plugins) / len(self.security_plugins) * 100
        )
        self.assertLessEqual(
            inconsistency_rate,
            80,
            f"Too many inconsistent security plugins: {inconsistency_rate:.1f}%",
        )

    def test_security_plugin_kb_references(self):
        """Test that security plugins have appropriate KB references"""
        plugins_with_kb = 0

        for plugin in self.security_plugins:
            kb = plugin.get("kb")
            if kb:
                plugins_with_kb += 1
                # KB should be a valid reference
                self.assertIsInstance(
                    kb, str, f"KB reference should be string for {plugin['plugin']}"
                )
                self.assertNotEqual(
                    kb.strip(),
                    "",
                    f"KB reference should not be empty for {plugin['plugin']}",
                )

        print(
            f"\nSecurity plugins with KB references: {plugins_with_kb}/{len(self.security_plugins)}"
        )

        # Some security plugins should have KB references
        if len(self.security_plugins) > 0:
            kb_percentage = (plugins_with_kb / len(self.security_plugins)) * 100
            self.assertGreaterEqual(
                kb_percentage,
                10,
                f"Expected more security plugins with KB references: {kb_percentage:.1f}%",
            )

    def test_security_plugin_bugzilla_references(self):
        """Test that security plugins have appropriate Bugzilla references"""
        plugins_with_bugzilla = 0

        for plugin in self.security_plugins:
            bugzilla = plugin.get("bugzilla")
            if bugzilla:
                plugins_with_bugzilla += 1
                # Bugzilla should be a valid reference
                self.assertIsInstance(
                    bugzilla,
                    str,
                    f"Bugzilla reference should be string for {plugin['plugin']}",
                )
                self.assertNotEqual(
                    bugzilla.strip(),
                    "",
                    f"Bugzilla reference should not be empty for {plugin['plugin']}",
                )

        print(
            f"\nSecurity plugins with Bugzilla references: {plugins_with_bugzilla}/{len(self.security_plugins)}"
        )

        # Some security plugins should have Bugzilla references
        if len(self.security_plugins) > 0:
            bugzilla_percentage = (
                plugins_with_bugzilla / len(self.security_plugins)
            ) * 100
            self.assertGreaterEqual(
                bugzilla_percentage,
                5,
                f"Expected more security plugins with Bugzilla references: {bugzilla_percentage:.1f}%",
            )
