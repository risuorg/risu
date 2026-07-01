#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Description: Tests for risuclient.config module
# Copyright (C) 2026 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

"""Tests for RisuConfig class."""

from __future__ import print_function

import os
import sys
import tempfile
import unittest

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from risuclient import config, exceptions


class TestRisuConfig(unittest.TestCase):
    """Test cases for RisuConfig class."""

    def test_init_default(self):
        """Test default initialization."""
        cfg = config.RisuConfig()

        self.assertIsNotNone(cfg.risu_dir)
        self.assertTrue(os.path.isdir(cfg.risu_dir))
        self.assertEqual(cfg.is_live, False)
        self.assertEqual(cfg.progress_char, "=")
        self.assertEqual(cfg.priority, 0)
        self.assertEqual(cfg.timeout, 30)
        self.assertIsInstance(cfg.plugins, list)
        self.assertEqual(len(cfg.plugins), 0)

    def test_init_custom_base_dir(self):
        """Test initialization with custom base directory."""
        base_dir = tempfile.mkdtemp()
        cfg = config.RisuConfig(base_dir=base_dir)

        self.assertEqual(cfg.risu_dir, base_dir)

    def test_get_risu_live(self):
        """Test get_risu_live method."""
        cfg = config.RisuConfig()

        cfg.is_live = False
        self.assertEqual(cfg.get_risu_live(), 0)

        cfg.is_live = True
        self.assertEqual(cfg.get_risu_live(), 1)

    def test_get_env_vars(self):
        """Test get_env_vars method."""
        cfg = config.RisuConfig()
        cfg.is_live = True
        cfg.risu_root = "/test/root"
        cfg.risu_tmp = "/test/tmp"

        env = cfg.get_env_vars()

        self.assertIn("RISU_BASE", env)
        self.assertEqual(env["RISU_LIVE"], "1")
        self.assertEqual(env["RISU_ROOT"], "/test/root")
        self.assertEqual(env["RISU_TMP"], "/test/tmp")

    def test_validate_success(self):
        """Test successful validation."""
        cfg = config.RisuConfig()
        # Use current directory which should exist
        cfg.risu_root = os.getcwd()

        # Should not raise
        self.assertTrue(cfg.validate())

    def test_validate_invalid_priority(self):
        """Test validation with invalid priority."""
        cfg = config.RisuConfig()
        cfg.priority = 1001  # Out of range

        with self.assertRaises(exceptions.ConfigError) as cm:
            cfg.validate()

        self.assertIn("Priority", str(cm.exception))

    def test_validate_invalid_timeout(self):
        """Test validation with invalid timeout."""
        cfg = config.RisuConfig()
        cfg.timeout = -1

        with self.assertRaises(exceptions.ConfigError) as cm:
            cfg.validate()

        self.assertIn("Timeout", str(cm.exception))

    def test_repr(self):
        """Test string representation."""
        cfg = config.RisuConfig()
        cfg.priority = 100

        repr_str = repr(cfg)

        self.assertIn("RisuConfig", repr_str)
        self.assertIn("priority=100", repr_str)


class TestRisuConfigFromOptions(unittest.TestCase):
    """Test RisuConfig.from_options factory method."""

    def test_from_options_basic(self):
        """Test creating config from options."""

        # Create mock options object
        class MockOptions(object):
            live = True
            quiet = False
            verbose = 2
            prio = 500
            include = ["test"]
            exclude = ["skip"]

        options = MockOptions()
        cfg = config.RisuConfig.from_options(options)

        self.assertEqual(cfg.is_live, True)
        self.assertEqual(cfg.quiet, False)
        self.assertEqual(cfg.verbose, 2)
        self.assertEqual(cfg.priority, 500)
        self.assertEqual(cfg.include, ["test"])
        self.assertEqual(cfg.exclude, ["skip"])

    def test_from_options_missing_attributes(self):
        """Test from_options with missing attributes."""

        # Options with only some attributes
        class MockOptions(object):
            live = True

        options = MockOptions()
        cfg = config.RisuConfig.from_options(options)

        # Should use defaults for missing attributes
        self.assertEqual(cfg.is_live, True)
        self.assertEqual(cfg.quiet, False)  # Default
        self.assertEqual(cfg.priority, 0)  # Default


if __name__ == "__main__":
    unittest.main()
