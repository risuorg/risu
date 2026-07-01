#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Description: Output formatting and colorization for Risu
# Copyright (C) 2026 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

"""
Output formatting and colorization.

This module handles all output formatting including:
- Terminal colorization
- Result formatting
- Progress indicators
- Text indentation
"""

from __future__ import print_function

import sys

# Return codes (must match shell.py and common-functions.sh)
RC_OKAY = 10
RC_FAILED = 20
RC_SKIPPED = 30
RC_INFO = 40


class Colors(object):
    """
    ANSI color codes for terminal output.

    Provides color codes as class attributes for easy access.
    """

    BLACK = "\033[30m"
    RED = "\033[31m"
    FAILED = RED  # Alias for failed state
    GREEN = "\033[32m"
    ORANGE = "\033[33m"
    BLUE = "\033[34m"
    MAGENTA = "\033[35m"
    PURPLE = MAGENTA  # Alias
    CYAN = "\033[36m"
    LIGHTGREY = "\033[37m"
    DARKGREY = "\033[90m"
    LIGHTRED = "\033[91m"
    LIGHTGREEN = "\033[92m"
    YELLOW = "\033[93m"
    LIGHTBLUE = "\033[94m"
    PINK = "\033[95m"
    LIGHTCYAN = "\033[96m"
    END = "\033[0m"
    RESET = END  # Alias


def colorize(text, color, stream=sys.stdout, force=False):
    """
    Colorize text for terminal output.

    Args:
        text (str): Text to colorize
        color (str): Color name (e.g., 'red', 'green', 'blue')
        stream (file): Output stream to check for TTY (default: stdout)
        force (bool): Force colorization even if not TTY (default: False)

    Returns:
        str: Colorized text with ANSI codes, or plain text if not TTY

    Example:
        >>> print(colorize("Error", "red"))
        \033[31mError\033[0m  # (if stdout is a TTY)
    """
    # Don't colorize if not TTY (unless forced)
    if not force and (not hasattr(stream, "isatty") or not stream.isatty()):
        return text

    # Get color code from Colors class
    color_code = getattr(Colors, color.upper(), None)
    if color_code is None:
        # Unknown color, return plain text
        return text

    return "{color}{text}{reset}".format(color=color_code, text=text, reset=Colors.END)


def format_return_code(returncode):
    """
    Format return code with appropriate color.

    Args:
        returncode (int): Plugin return code (RC_OKAY, RC_FAILED, etc.)

    Returns:
        tuple: (status_text, color_name) for the return code

    Example:
        >>> text, color = format_return_code(RC_OKAY)
        >>> print(colorize(text, color))
    """
    # Map return codes to (text, color)
    status_map = {
        RC_OKAY: ("okay", "green"),
        RC_FAILED: ("failed", "red"),
        RC_SKIPPED: ("skipped", "orange"),
        RC_INFO: ("info", "blue"),
    }

    return status_map.get(returncode, ("unknown", "magenta"))


def format_result_text(returncode):
    """
    Get colorized result text for return code.

    Args:
        returncode (int): Plugin return code

    Returns:
        str: Colorized status text

    Example:
        >>> print(format_result_text(RC_OKAY))
        \033[32mokay\033[0m  # Green "okay"
    """
    text, color = format_return_code(returncode)
    return colorize(text, color)


def indent_text(text, amount, indent_char=" "):
    """
    Indent text by specified amount.

    Args:
        text (str): Text to indent (may contain newlines)
        amount (int): Number of indent characters to add
        indent_char (str): Character to use for indentation (default: space)

    Returns:
        str: Indented text

    Example:
        >>> print(indent_text("Line 1\\nLine 2", 4))
            Line 1
            Line 2
    """
    indent = indent_char * amount
    lines = text.split("\n")
    return "\n".join(indent + line for line in lines)


class ProgressIndicator(object):
    """
    Progress indicator for plugin execution.

    Shows progress as plugins execute using a character indicator.
    """

    def __init__(
        self, total, char="=", colour="blue", start="[", end="]", stream=sys.stdout
    ):
        """
        Initialize progress indicator.

        Args:
            total (int): Total number of items to process
            char (str): Character to use for progress (default: '=')
            colour (str): Color name for progress char (default: 'blue')
            start (str): String to print at start (default: '[')
            end (str): String to print at end (default: ']')
            stream (file): Output stream (default: stdout)
        """
        self.total = total
        self.current = 0
        self.char = char
        self.colour = colour
        self.start = start
        self.end = end
        self.stream = stream
        self.started = False

    def begin(self):
        """Start progress indicator."""
        if self.start:
            self.stream.write(self.start)
            self.stream.flush()
        self.started = True

    def tick(self):
        """Increment progress by one."""
        if not self.started:
            self.begin()

        self.current += 1
        colored_char = colorize(self.char, self.colour, self.stream)
        self.stream.write(colored_char)
        self.stream.flush()

    def finish(self):
        """Finish progress indicator."""
        if not self.started:
            return

        if self.end:
            self.stream.write(self.end)
        self.stream.write("\n")
        self.stream.flush()


def format_plugin_result(plugin, result, verbose=False):
    """
    Format plugin execution result for display.

    Args:
        plugin (dict): Plugin dictionary with metadata
        result (dict): Execution result with 'rc', 'out', 'err'
        verbose (bool): Include verbose output (default: False)

    Returns:
        str: Formatted result string

    Example:
        >>> plugin = {'plugin': '/path/to/plugin.sh', 'id': 'plugin-id'}
        >>> result = {'rc': RC_OKAY, 'out': '', 'err': ''}
        >>> print(format_plugin_result(plugin, result))
        # /path/to/plugin.sh: okay
    """
    plugin_path = plugin.get("plugin", "unknown")
    returncode = result.get("rc", -1)

    # Format status
    status = format_result_text(returncode)

    # Build output
    output = "# {path}: {status}".format(path=plugin_path, status=status)

    # Add error output if present
    err = result.get("err", "")
    if err and err.strip():
        output += "\n" + indent_text(err.strip(), 4)

    # Add standard output in verbose mode
    if verbose:
        out = result.get("out", "")
        if out and out.strip():
            output += "\n" + indent_text(out.strip(), 4)

    return output


def format_summary(total, passed, failed, skipped, info):
    """
    Format execution summary.

    Args:
        total (int): Total plugins executed
        passed (int): Number that passed (RC_OKAY)
        failed (int): Number that failed (RC_FAILED)
        skipped (int): Number that were skipped (RC_SKIPPED)
        info (int): Number that were informational (RC_INFO)

    Returns:
        str: Formatted summary string

    Example:
        >>> print(format_summary(100, 85, 10, 3, 2))
        ========================================
        Total:   100
        Passed:   85 (85.0%)
        Failed:   10 (10.0%)
        Skipped:   3 (3.0%)
        Info:      2 (2.0%)
        ========================================
    """
    lines = [
        "=" * 60,
        "Execution Summary:",
        "  Total:   {total:4d}".format(total=total),
    ]

    if total > 0:
        lines.extend(
            [
                "  Passed:  {count:4d} ({pct:5.1f}%)".format(
                    count=passed, pct=100.0 * passed / total
                ),
                "  Failed:  {count:4d} ({pct:5.1f}%)".format(
                    count=failed, pct=100.0 * failed / total
                ),
                "  Skipped: {count:4d} ({pct:5.1f}%)".format(
                    count=skipped, pct=100.0 * skipped / total
                ),
                "  Info:    {count:4d} ({pct:5.1f}%)".format(
                    count=info, pct=100.0 * info / total
                ),
            ]
        )

    lines.append("=" * 60)
    return "\n".join(lines)
