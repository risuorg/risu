#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Description: OpenStack plugin specific tests
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


class OpenStackPluginTest(TestCase):
    def setUp(self):
        """Set up test environment"""
        self.tmpdir = tempfile.mkdtemp(prefix="risu-openstack-test-")
        self.openstack_plugins = risu.findplugins(
            folders=[os.path.join(risu.risudir, "plugins", "core", "openstack")]
        )

    def tearDown(self):
        """Clean up test environment"""
        if os.path.exists(self.tmpdir):
            shutil.rmtree(self.tmpdir)

    def test_openstack_plugins_exist(self):
        """Test that OpenStack plugins exist and are categorized correctly"""
        categories = {}

        for plugin in self.openstack_plugins:
            plugin_path = plugin["plugin"]
            parts = plugin_path.split("/")
            if "openstack" in parts:
                openstack_index = parts.index("openstack")
                if openstack_index + 1 < len(parts):
                    category = parts[openstack_index + 1]
                    if category not in categories:
                        categories[category] = 0
                    categories[category] += 1

        print("\nOpenStack plugin categories:")
        for category, count in sorted(categories.items()):
            print(f"  {category}: {count} plugins")

        # Assert we have plugins in key OpenStack categories
        expected_categories = [
            "nova",
            "neutron",
            "keystone",
            "glance",
            "cinder",
            "mysql",
        ]
        for category in expected_categories:
            self.assertIn(category, categories, f"Missing {category} plugins")

    def test_nova_plugins(self):
        """Test Nova-specific plugins"""
        nova_plugins = [p for p in self.openstack_plugins if "nova" in p["plugin"]]

        self.assertGreater(len(nova_plugins), 0, "Should have Nova plugins")

        # Test that Nova plugins have appropriate priorities
        for plugin in nova_plugins:
            self.assertIsNotNone(
                plugin.get("priority"),
                f"Nova plugin {plugin['plugin']} should have priority",
            )

    def test_neutron_plugins(self):
        """Test Neutron-specific plugins"""
        neutron_plugins = [
            p for p in self.openstack_plugins if "neutron" in p["plugin"]
        ]

        self.assertGreater(len(neutron_plugins), 0, "Should have Neutron plugins")

        # Test that Neutron plugins have appropriate priorities
        for plugin in neutron_plugins:
            self.assertIsNotNone(
                plugin.get("priority"),
                f"Neutron plugin {plugin['plugin']} should have priority",
            )

    def test_keystone_plugins(self):
        """Test Keystone-specific plugins"""
        keystone_plugins = [
            p for p in self.openstack_plugins if "keystone" in p["plugin"]
        ]

        self.assertGreater(len(keystone_plugins), 0, "Should have Keystone plugins")

        # Test that Keystone plugins have appropriate priorities
        for plugin in keystone_plugins:
            self.assertIsNotNone(
                plugin.get("priority"),
                f"Keystone plugin {plugin['plugin']} should have priority",
            )

    def test_database_plugins(self):
        """Test database-related plugins (MySQL, MongoDB, etc.)"""
        db_plugins = [
            p
            for p in self.openstack_plugins
            if any(db in p["plugin"] for db in ["mysql", "mongodb", "redis"])
        ]

        self.assertGreater(len(db_plugins), 0, "Should have database plugins")

        # Test that database plugins have high priority (600-799 range)
        for plugin in db_plugins:
            priority = plugin.get("priority")
            if priority:
                try:
                    prio_val = int(priority)
                    self.assertGreaterEqual(
                        prio_val,
                        600,
                        f"Database plugin {plugin['plugin']} should have high priority",
                    )
                except ValueError:
                    self.fail(
                        f"Database plugin {plugin['plugin']} has invalid priority: {priority}"
                    )

    def test_rabbitmq_plugins(self):
        """Test RabbitMQ-specific plugins"""
        rabbitmq_plugins = [
            p for p in self.openstack_plugins if "rabbitmq" in p["plugin"]
        ]

        self.assertGreater(len(rabbitmq_plugins), 0, "Should have RabbitMQ plugins")

        # Test that RabbitMQ plugins have appropriate priorities
        for plugin in rabbitmq_plugins:
            priority = plugin.get("priority")
            if priority:
                try:
                    prio_val = int(priority)
                    self.assertGreaterEqual(
                        prio_val,
                        600,
                        f"RabbitMQ plugin {plugin['plugin']} should have high priority",
                    )
                except ValueError:
                    self.fail(
                        f"RabbitMQ plugin {plugin['plugin']} has invalid priority: {priority}"
                    )

    def test_haproxy_plugins(self):
        """Test HAProxy-specific plugins"""
        haproxy_plugins = [
            p for p in self.openstack_plugins if "haproxy" in p["plugin"]
        ]

        if haproxy_plugins:  # Only test if HAProxy plugins exist
            for plugin in haproxy_plugins:
                self.assertIsNotNone(
                    plugin.get("priority"),
                    f"HAProxy plugin {plugin['plugin']} should have priority",
                )

    def test_ceph_plugins(self):
        """Test Ceph-specific plugins in OpenStack context"""
        ceph_plugins = [p for p in self.openstack_plugins if "ceph" in p["plugin"]]

        if ceph_plugins:  # Only test if Ceph plugins exist
            for plugin in ceph_plugins:
                priority = plugin.get("priority")
                if priority:
                    try:
                        prio_val = int(priority)
                        self.assertGreaterEqual(
                            prio_val,
                            600,
                            f"Ceph plugin {plugin['plugin']} should have high priority",
                        )
                    except ValueError:
                        self.fail(
                            f"Ceph plugin {plugin['plugin']} has invalid priority: {priority}"
                        )

    def test_container_plugins(self):
        """Test container-related plugins in OpenStack context"""
        container_plugins = [
            p
            for p in self.openstack_plugins
            if any(
                container in p["plugin"]
                for container in ["containers", "docker", "podman"]
            )
        ]

        if container_plugins:  # Only test if container plugins exist
            for plugin in container_plugins:
                self.assertIsNotNone(
                    plugin.get("priority"),
                    f"Container plugin {plugin['plugin']} should have priority",
                )

    def test_systemd_plugins(self):
        """Test systemd-related plugins in OpenStack context"""
        systemd_plugins = [
            p for p in self.openstack_plugins if "systemd" in p["plugin"]
        ]

        if systemd_plugins:  # Only test if systemd plugins exist
            for plugin in systemd_plugins:
                priority = plugin.get("priority")
                if priority:
                    try:
                        prio_val = int(priority)
                        self.assertGreaterEqual(
                            prio_val,
                            800,
                            f"SystemD plugin {plugin['plugin']} should have high priority",
                        )
                    except ValueError:
                        self.fail(
                            f"SystemD plugin {plugin['plugin']} has invalid priority: {priority}"
                        )

    def test_openstack_plugin_metadata(self):
        """Test that OpenStack plugins have proper metadata"""
        for plugin in self.openstack_plugins:
            # All OpenStack plugins should have description
            self.assertIsNotNone(
                plugin.get("description"),
                f"OpenStack plugin {plugin['plugin']} should have description",
            )
            self.assertNotEqual(
                plugin.get("description", "").strip(),
                "",
                f"OpenStack plugin {plugin['plugin']} should have non-empty description",
            )

            # All OpenStack plugins should have long_name
            self.assertIsNotNone(
                plugin.get("long_name"),
                f"OpenStack plugin {plugin['plugin']} should have long_name",
            )
            self.assertNotEqual(
                plugin.get("long_name", "").strip(),
                "",
                f"OpenStack plugin {plugin['plugin']} should have non-empty long_name",
            )

            # All OpenStack plugins should have priority
            self.assertIsNotNone(
                plugin.get("priority"),
                f"OpenStack plugin {plugin['plugin']} should have priority",
            )

            # Priority should be valid integer
            priority = plugin.get("priority")
            if priority:
                try:
                    prio_val = int(priority)
                    self.assertGreaterEqual(
                        prio_val,
                        1,
                        f"OpenStack plugin {plugin['plugin']} priority should be >= 1",
                    )
                    self.assertLessEqual(
                        prio_val,
                        999,
                        f"OpenStack plugin {plugin['plugin']} priority should be <= 999",
                    )
                except ValueError:
                    self.fail(
                        f"OpenStack plugin {plugin['plugin']} has invalid priority: {priority}"
                    )

    def test_openstack_plugin_execution(self):
        """Test execution of OpenStack plugins"""
        successful_runs = 0
        failed_runs = 0

        # Test a subset of OpenStack plugins
        test_plugins = self.openstack_plugins[:50]  # Test first 50 to avoid timeout

        for plugin in test_plugins:
            try:
                _ = risu.doplugin(plugin=plugin, path=self.tmpdir, options={})
                successful_runs += 1
            except Exception as e:
                failed_runs += 1
                print(f"Error running OpenStack plugin {plugin['plugin']}: {e}")

        total_tested = successful_runs + failed_runs
        success_rate = (successful_runs / total_tested) * 100 if total_tested > 0 else 0

        print("\nOpenStack plugin execution results:")
        print(f"  Total tested: {total_tested}")
        print(f"  Successful: {successful_runs} ({success_rate:.1f}%)")
        print(f"  Failed: {failed_runs}")

        # Assert minimum success rate for OpenStack plugins
        self.assertGreaterEqual(
            success_rate,
            60,
            f"OpenStack plugin success rate too low: {success_rate:.1f}%",
        )

    def test_openstack_plugin_priority_distribution(self):
        """Test priority distribution for OpenStack plugins"""
        priority_counts = {}

        for plugin in self.openstack_plugins:
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

        print("\nOpenStack plugin priority distribution:")
        for prio_range, count in sorted(priority_counts.items()):
            print(f"  {prio_range}: {count} plugins")

        # Most OpenStack plugins should be in medium priority range (600-799)
        medium_priority = priority_counts.get("600-699", 0) + priority_counts.get(
            "700-799", 0
        )
        total_with_priority = sum(priority_counts.values())

        if total_with_priority > 0:
            medium_percentage = (medium_priority / total_with_priority) * 100
            self.assertGreaterEqual(
                medium_percentage,
                30,
                f"Expected more medium priority OpenStack plugins: {medium_percentage:.1f}%",
            )
