#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Unit tests for maguiclient/autogroup.py
# Copyright (C) 2026 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

from __future__ import print_function

import os
import sys
import unittest

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

import risuclient.shell as risu
from maguiclient import autogroup


class TestAutoGroupManager(unittest.TestCase):
    """Test cases for AutoGroupManager class"""

    def setUp(self):
        """Set up test autogroup manager"""
        self.manager = autogroup.AutoGroupManager()

    def test_initialization(self):
        """Test manager initializes with empty dicts"""
        self.assertEqual(self.manager.groups, {})
        self.assertEqual(self.manager.processed_groups, {})

    def test_generate_groups_simple(self):
        """Test group generation with simple metadata"""
        metadata_results = [
            {
                "name": "release",
                "sosreport": {
                    "host1": {"rc": risu.RC_OKAY, "err": "7.5"},
                    "host2": {"rc": risu.RC_OKAY, "err": "7.5"},
                    "host3": {"rc": risu.RC_OKAY, "err": "7.6"},
                },
            }
        ]

        groups = self.manager.generate_groups(metadata_results)

        # Should create group for hosts with same release
        self.assertIn("release-7.5", groups)
        self.assertEqual(set(groups["release-7.5"]), {"host1", "host2"})

    def test_generate_groups_multiple_metadata(self):
        """Test group generation with multiple metadata types"""
        metadata_results = [
            {
                "name": "release",
                "sosreport": {
                    "host1": {"rc": risu.RC_OKAY, "err": "7.5"},
                    "host2": {"rc": risu.RC_OKAY, "err": "7.5"},
                    "host3": {"rc": risu.RC_OKAY, "err": "7.6"},
                },
            },
            {
                "name": "role",
                "sosreport": {
                    "host1": {"rc": risu.RC_OKAY, "err": "controller"},
                    "host2": {"rc": risu.RC_OKAY, "err": "compute"},
                    "host3": {"rc": risu.RC_OKAY, "err": "controller"},
                },
            },
        ]

        groups = self.manager.generate_groups(metadata_results)

        # Should create multiple groups
        self.assertIn("release-7.5", groups)
        self.assertIn("role-controller", groups)

    def test_generate_groups_excludes_all_hosts(self):
        """Test that groups with all hosts are excluded"""
        metadata_results = [
            {
                "name": "arch",
                "sosreport": {
                    "host1": {"rc": risu.RC_OKAY, "err": "x86_64"},
                    "host2": {"rc": risu.RC_OKAY, "err": "x86_64"},
                    "host3": {"rc": risu.RC_OKAY, "err": "x86_64"},
                },
            }
        ]

        groups = self.manager.generate_groups(metadata_results)

        # Should not create group with all hosts
        self.assertEqual(len(groups), 0)

    def test_generate_groups_excludes_single_host(self):
        """Test that groups with single host are excluded"""
        metadata_results = [
            {
                "name": "uuid",
                "sosreport": {
                    "host1": {"rc": risu.RC_OKAY, "err": "UUID1"},
                    "host2": {"rc": risu.RC_OKAY, "err": "UUID2"},
                    "host3": {"rc": risu.RC_OKAY, "err": "UUID3"},
                },
            }
        ]

        groups = self.manager.generate_groups(metadata_results)

        # Should not create groups with single host
        self.assertEqual(len(groups), 0)

    def test_find_next_target(self):
        """Test finding next target group"""
        available_groups = {
            "group1": ["host1", "host2", "host3"],
            "group2": ["host1", "host2"],
            "group3": ["host3"],
        }

        target, _, todel = self.manager.find_next_target(available_groups)

        # Should return a valid target
        self.assertIn(target, available_groups.keys())

        # The algorithm finds host with minimum appearances
        # host3 appears in 2 groups (group1, group3)
        # host1 appears in 2 groups (group1, group2)
        # host2 appears in 2 groups (group1, group2)
        # Algorithm will pick first encountered minimum
        self.assertIsNotNone(target)
        self.assertIsNotNone(todel)

    def test_find_next_target_empty(self):
        """Test finding target with empty groups"""
        target, _, todel = self.manager.find_next_target({})

        self.assertEqual(target, "")
        self.assertFalse(todel)

    def test_is_duplicate_group(self):
        """Test duplicate group detection"""
        self.manager.mark_processed("/tmp/file1.json", ["host1", "host2"])

        # Same hosts should be duplicate
        is_dup, file_path = self.manager.is_duplicate_group(["host2", "host1"])
        self.assertTrue(is_dup)
        self.assertEqual(file_path, "/tmp/file1.json")

        # Different hosts should not be duplicate
        is_dup, _ = self.manager.is_duplicate_group(["host1", "host3"])
        self.assertFalse(is_dup)

    def test_mark_processed(self):
        """Test marking groups as processed"""
        self.manager.mark_processed("/tmp/file1.json", ["host1", "host2"])
        self.manager.mark_processed("/tmp/file2.json", ["host3", "host4"])

        self.assertEqual(len(self.manager.processed_groups), 2)
        self.assertIn("/tmp/file1.json", self.manager.processed_groups)

    def test_get_statistics_empty(self):
        """Test statistics with no groups"""
        stats = self.manager.get_statistics()

        self.assertEqual(stats["total_groups"], 0)
        self.assertEqual(stats["total_hosts"], 0)

    def test_get_statistics_with_groups(self):
        """Test statistics with groups"""
        self.manager.groups = {
            "group1": ["host1", "host2", "host3"],
            "group2": ["host1", "host2"],
            "group3": ["host4", "host5"],
        }

        stats = self.manager.get_statistics()

        self.assertEqual(stats["total_groups"], 3)
        self.assertEqual(stats["total_hosts"], 5)  # Unique hosts
        self.assertEqual(stats["groups"]["group1"], 3)


class TestLegacyFunctions(unittest.TestCase):
    """Test legacy function wrappers for backward compatibility"""

    def test_autogroups_function(self):
        """Test legacy autogroups function"""
        metadata_results = [
            {
                "name": "release",
                "sosreport": {
                    "host1": {"rc": risu.RC_OKAY, "err": "7.5"},
                    "host2": {"rc": risu.RC_OKAY, "err": "7.5"},
                    "host3": {"rc": risu.RC_OKAY, "err": "7.6"},
                },
            }
        ]

        groups = autogroup.autogroups(metadata_results)

        self.assertIn("release-7.5", groups)
        self.assertEqual(set(groups["release-7.5"]), {"host1", "host2"})

    def test_findtarget_function(self):
        """Test legacy findtarget function"""
        available_groups = {
            "group1": ["host1", "host2"],
            "group2": ["host3"],
        }

        target, _, todel = autogroup.findtarget(available_groups)

        # Should return a valid target
        self.assertIn(target, available_groups.keys())
        # Should identify a sosreport that can be deleted
        self.assertIsNotNone(todel)


if __name__ == "__main__":
    unittest.main()
