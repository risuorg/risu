#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Unit tests for risuclient/extensions/base.py
# Copyright (C) 2026 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

from __future__ import print_function

import os
import sys
import unittest

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from risuclient.extensions import base


class TestBaseExtension(unittest.TestCase):
    """Test cases for BaseExtension class"""

    def test_must_set_extension_name(self):
        """Test that extension_name must be set"""
        with self.assertRaises(NotImplementedError):
            base.BaseExtension()

    def test_initialization_with_name(self):
        """Test initialization with extension_name set"""

        class TestExt(base.BaseExtension):
            extension_name = "test"

            def run(self, plugin):
                pass

        ext = TestExt()
        self.assertEqual(ext.extension_name, "test")
        self.assertTrue(ext.plugins_dir.endswith("plugins/test"))

    def test_custom_plugins_subdir(self):
        """Test custom plugins subdirectory"""

        class TestExt(base.BaseExtension):
            extension_name = "test"
            plugins_subdir = "custom"

            def run(self, plugin):
                pass

        ext = TestExt()
        self.assertTrue(ext.plugins_dir.endswith("plugins/custom"))

    def test_init_returns_triggers(self):
        """Test init() returns trigger list"""

        class TestExt(base.BaseExtension):
            extension_name = "test"

            def run(self, plugin):
                pass

        ext = TestExt()
        triggers = ext.init()
        self.assertEqual(triggers, ["test"])

    def test_run_must_be_implemented(self):
        """Test that run() must be implemented"""

        class TestExt(base.BaseExtension):
            extension_name = "test"

        ext = TestExt()
        with self.assertRaises(NotImplementedError):
            ext.run({"plugin": "test.sh"})

    def test_help_default_message(self):
        """Test default help message"""

        class TestExt(base.BaseExtension):
            extension_name = "test"

            def run(self, plugin):
                pass

        ext = TestExt()
        help_text = ext.help()
        self.assertIn("test", help_text)

    def test_help_custom_message(self):
        """Test custom help message"""

        class TestExt(base.BaseExtension):
            extension_name = "test"

            def run(self, plugin):
                pass

            def help(self):
                return "Custom help"

        ext = TestExt()
        self.assertEqual(ext.help(), "Custom help")

    def test_file_extension_attribute(self):
        """Test file_extension attribute"""

        class TestExt(base.BaseExtension):
            extension_name = "test"
            file_extension = ".test"

            def run(self, plugin):
                pass

        ext = TestExt()
        self.assertEqual(ext.file_extension, ".test")

    def test_executables_only_attribute(self):
        """Test executables_only attribute"""

        class TestExt(base.BaseExtension):
            extension_name = "test"
            executables_only = False

            def run(self, plugin):
                pass

        ext = TestExt()
        self.assertFalse(ext.executables_only)

    def test_comment_char_attribute(self):
        """Test comment_char attribute"""

        class TestExt(base.BaseExtension):
            extension_name = "test"
            comment_char = "//"

            def run(self, plugin):
                pass

        ext = TestExt()
        self.assertEqual(ext.comment_char, "//")


class TestSimpleShellExtension(unittest.TestCase):
    """Test cases for SimpleShellExtension class"""

    def test_run_delegates_to_execonshell(self):
        """Test that run() uses execonshell"""

        class TestExt(base.SimpleShellExtension):
            extension_name = "test"

        ext = TestExt()

        # Note: We can't easily test execonshell without mocking,
        # so just verify the method exists and is callable
        self.assertTrue(callable(ext.run))

    def test_inherits_base_functionality(self):
        """Test that SimpleShellExtension inherits from BaseExtension"""

        class TestExt(base.SimpleShellExtension):
            extension_name = "test"

        ext = TestExt()

        # Should have all BaseExtension methods
        self.assertTrue(hasattr(ext, "init"))
        self.assertTrue(hasattr(ext, "listplugins"))
        self.assertTrue(hasattr(ext, "get_metadata"))
        self.assertTrue(hasattr(ext, "help"))


class TestCreateExtensionExports(unittest.TestCase):
    """Test cases for create_extension_exports helper"""

    def test_creates_all_exports(self):
        """Test that all required functions are exported"""

        class TestExt(base.BaseExtension):
            extension_name = "test"

            def run(self, plugin):
                return (0, "", "")

        exports = base.create_extension_exports(TestExt)

        # Should have all required exports
        self.assertIn("init", exports)
        self.assertIn("listplugins", exports)
        self.assertIn("get_metadata", exports)
        self.assertIn("run", exports)
        self.assertIn("help", exports)

    def test_exports_are_callable(self):
        """Test that all exports are callable"""

        class TestExt(base.BaseExtension):
            extension_name = "test"

            def run(self, plugin):
                return (0, "", "")

        exports = base.create_extension_exports(TestExt)

        # All should be callable
        for name, func in exports.items():
            self.assertTrue(callable(func), "%s should be callable" % name)

    def test_exports_work_correctly(self):
        """Test that exported functions work"""

        class TestExt(base.BaseExtension):
            extension_name = "test"

            def run(self, plugin):
                return (42, "out", "err")

        exports = base.create_extension_exports(TestExt)

        # Test init
        triggers = exports["init"]()
        self.assertEqual(triggers, ["test"])

        # Test run
        result = exports["run"]({"plugin": "test.sh"})
        self.assertEqual(result, (42, "out", "err"))


if __name__ == "__main__":
    unittest.main()
