#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Description: Tests for risuclient.formatter module
# Copyright (C) 2026 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

"""Tests for formatting and colorization."""

from __future__ import print_function

import os
import sys
import unittest

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from risuclient import formatter


class TestColors(unittest.TestCase):
    """Test Colors class."""

    def test_colors_defined(self):
        """Test that color codes are defined."""
        self.assertIsNotNone(formatter.Colors.RED)
        self.assertIsNotNone(formatter.Colors.GREEN)
        self.assertIsNotNone(formatter.Colors.BLUE)
        self.assertIsNotNone(formatter.Colors.END)

    def test_color_aliases(self):
        """Test color aliases."""
        self.assertEqual(formatter.Colors.FAILED, formatter.Colors.RED)
        self.assertEqual(formatter.Colors.PURPLE, formatter.Colors.MAGENTA)


class TestColorize(unittest.TestCase):
    """Test colorize function."""

    def test_colorize_basic(self):
        """Test basic colorization."""
        # Force colorization
        result = formatter.colorize("test", "red", force=True)

        self.assertIn("test", result)
        self.assertIn(formatter.Colors.RED, result)
        self.assertIn(formatter.Colors.END, result)

    def test_colorize_unknown_color(self):
        """Test colorize with unknown color."""
        # Should return plain text
        result = formatter.colorize("test", "unknown_color", force=True)
        self.assertEqual(result, "test")

    def test_colorize_without_force(self):
        """Test colorize without force on non-TTY."""
        # Should return plain text when not TTY and not forced
        import io

        stream = io.StringIO() if sys.version_info >= (3, 0) else None

        if stream:
            result = formatter.colorize("test", "red", stream=stream, force=False)
            self.assertEqual(result, "test")


class TestFormatReturnCode(unittest.TestCase):
    """Test format_return_code function."""

    def test_format_okay(self):
        """Test formatting RC_OKAY."""
        text, color = formatter.format_return_code(formatter.RC_OKAY)
        self.assertEqual(text, "okay")
        self.assertEqual(color, "green")

    def test_format_failed(self):
        """Test formatting RC_FAILED."""
        text, color = formatter.format_return_code(formatter.RC_FAILED)
        self.assertEqual(text, "failed")
        self.assertEqual(color, "red")

    def test_format_skipped(self):
        """Test formatting RC_SKIPPED."""
        text, color = formatter.format_return_code(formatter.RC_SKIPPED)
        self.assertEqual(text, "skipped")
        self.assertEqual(color, "orange")

    def test_format_info(self):
        """Test formatting RC_INFO."""
        text, color = formatter.format_return_code(formatter.RC_INFO)
        self.assertEqual(text, "info")
        self.assertEqual(color, "blue")

    def test_format_unknown(self):
        """Test formatting unknown return code."""
        text, color = formatter.format_return_code(999)
        self.assertEqual(text, "unknown")
        self.assertEqual(color, "magenta")


class TestIndentText(unittest.TestCase):
    """Test indent_text function."""

    def test_indent_single_line(self):
        """Test indenting single line."""
        result = formatter.indent_text("test", 4)
        self.assertEqual(result, "    test")

    def test_indent_multiple_lines(self):
        """Test indenting multiple lines."""
        text = "line1\nline2\nline3"
        result = formatter.indent_text(text, 2)

        lines = result.split("\n")
        self.assertEqual(len(lines), 3)
        for line in lines:
            self.assertTrue(line.startswith("  "))

    def test_indent_custom_char(self):
        """Test indenting with custom character."""
        result = formatter.indent_text("test", 3, indent_char="-")
        self.assertEqual(result, "---test")


class TestProgressIndicator(unittest.TestCase):
    """Test ProgressIndicator class."""

    def test_init(self):
        """Test initialization."""
        import io

        stream = io.StringIO() if sys.version_info >= (3, 0) else None

        if stream:
            progress = formatter.ProgressIndicator(total=10, char="=", stream=stream)

            self.assertEqual(progress.total, 10)
            self.assertEqual(progress.current, 0)
            self.assertEqual(progress.char, "=")


class TestFormatSummary(unittest.TestCase):
    """Test format_summary function."""

    def test_format_summary_basic(self):
        """Test basic summary formatting."""
        result = formatter.format_summary(
            total=100, passed=85, failed=10, skipped=3, info=2
        )

        self.assertIn("100", result)
        self.assertIn("85", result)
        self.assertIn("10", result)
        self.assertIn("3", result)
        self.assertIn("2", result)
        self.assertIn("%", result)  # Should include percentages

    def test_format_summary_zero_total(self):
        """Test summary with zero total."""
        result = formatter.format_summary(
            total=0, passed=0, failed=0, skipped=0, info=0
        )

        self.assertIn("0", result)
        # Should not crash with division by zero


if __name__ == "__main__":
    unittest.main()
