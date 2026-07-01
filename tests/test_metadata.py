#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Description: Tests for risuclient.metadata module
# Copyright (C) 2026 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

"""Tests for metadata extraction and validation."""

from __future__ import print_function

import os
import sys
import tempfile
import unittest

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from risuclient import exceptions, metadata


class TestPluginMetadata(unittest.TestCase):
    """Test cases for PluginMetadata class."""

    def test_init(self):
        """Test initialization."""
        meta = metadata.PluginMetadata(
            long_name="Test Plugin", description="Test description", priority=500
        )

        self.assertEqual(meta.long_name, "Test Plugin")
        self.assertEqual(meta.description, "Test description")
        self.assertEqual(meta.priority, 500)
        self.assertIsNone(meta.bugzilla)
        self.assertIsNone(meta.kb)
        self.assertEqual(meta.tags, [])

    def test_validate_valid(self):
        """Test validation of valid metadata."""
        meta = metadata.PluginMetadata(
            long_name="Test", description="Test description", priority=500
        )

        errors = meta.validate()
        self.assertEqual(errors, [])

    def test_validate_missing_long_name(self):
        """Test validation with missing long_name."""
        meta = metadata.PluginMetadata(
            long_name="", description="Test description", priority=500
        )

        errors = meta.validate()
        self.assertTrue(len(errors) > 0)
        self.assertTrue(any("long_name" in e for e in errors))

    def test_validate_invalid_priority(self):
        """Test validation with invalid priority."""
        meta = metadata.PluginMetadata(
            long_name="Test",
            description="Test description",
            priority=1000,  # Out of range
        )

        errors = meta.validate()
        self.assertTrue(len(errors) > 0)
        self.assertTrue(any("priority" in e for e in errors))

    def test_get_category(self):
        """Test category detection."""
        test_cases = [
            (950, "critical"),
            (850, "high"),
            (700, "medium"),
            (500, "medium_low"),
            (300, "low"),
            (150, "very_low"),
            (50, "metadata"),
        ]

        for priority, expected_category in test_cases:
            meta = metadata.PluginMetadata(
                long_name="Test", description="Test", priority=priority
            )
            self.assertEqual(meta.get_category(), expected_category)

    def test_to_dict(self):
        """Test conversion to dictionary."""
        meta = metadata.PluginMetadata(
            long_name="Test Plugin",
            description="Test description",
            priority=500,
            bugzilla="http://example.com/bug/123",
            kb="http://example.com/kb/456",
        )

        d = meta.to_dict()

        self.assertEqual(d["long_name"], "Test Plugin")
        self.assertEqual(d["description"], "Test description")
        self.assertEqual(d["priority"], 500)
        self.assertEqual(d["bugzilla"], "http://example.com/bug/123")
        self.assertEqual(d["kb"], "http://example.com/kb/456")
        self.assertIn("category", d)


class TestExtractMetadata(unittest.TestCase):
    """Test metadata extraction from files."""

    def setUp(self):
        """Create temporary plugin file for testing."""
        self.temp_file = tempfile.NamedTemporaryFile(
            mode="w", suffix=".sh", delete=False
        )

    def tearDown(self):
        """Clean up temporary file."""
        try:
            os.unlink(self.temp_file.name)
        except (IOError, OSError):
            pass

    def test_extract_valid_metadata(self):
        """Test extracting valid metadata."""
        plugin_content = """#!/bin/bash
# long_name: Test Plugin
# description: This is a test plugin
# priority: 500
# bugzilla: http://example.com/bug/123
# kb: http://example.com/kb/456

echo "test"
"""
        self.temp_file.write(plugin_content)
        self.temp_file.close()

        meta = metadata.extract_metadata_from_file(self.temp_file.name)

        self.assertEqual(meta.long_name, "Test Plugin")
        self.assertEqual(meta.description, "This is a test plugin")
        self.assertEqual(meta.priority, 500)
        self.assertEqual(meta.bugzilla, "http://example.com/bug/123")
        self.assertEqual(meta.kb, "http://example.com/kb/456")

    def test_extract_missing_required_field(self):
        """Test extraction with missing required field."""
        plugin_content = """#!/bin/bash
# long_name: Test Plugin
# description: This is a test plugin
# Missing priority!

echo "test"
"""
        self.temp_file.write(plugin_content)
        self.temp_file.close()

        with self.assertRaises(exceptions.PluginMetadataError) as cm:
            metadata.extract_metadata_from_file(self.temp_file.name)

        self.assertIn("missing", str(cm.exception).lower())

    def test_extract_invalid_priority(self):
        """Test extraction with invalid priority."""
        plugin_content = """#!/bin/bash
# long_name: Test Plugin
# description: This is a test plugin
# priority: not_a_number

echo "test"
"""
        self.temp_file.write(plugin_content)
        self.temp_file.close()

        with self.assertRaises(exceptions.PluginMetadataError) as cm:
            metadata.extract_metadata_from_file(self.temp_file.name)

        self.assertIn("priority", str(cm.exception).lower())


if __name__ == "__main__":
    unittest.main()
