#!/usr/bin/env python
#
# Description: Custom exceptions for Risu framework
# Copyright (C) 2026 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

"""
Custom exception hierarchy for Risu framework.

This module defines all custom exceptions used throughout Risu.
Using specific exception types makes error handling more precise
and debugging easier.
"""



class RisuError(Exception):
    """
    Base exception for all Risu-specific errors.

    All custom exceptions in Risu should inherit from this class.
    This allows catching all Risu errors with a single except clause.
    """



class ConfigError(RisuError):
    """
    Configuration-related error.

    Raised when:
    - Configuration file is invalid or malformed
    - Required configuration option is missing
    - Configuration value is out of valid range
    """



class PluginError(RisuError):
    """
    Base exception for plugin-related errors.

    Parent class for all plugin execution and loading errors.
    """



class PluginNotFoundError(PluginError):
    """
    Plugin file not found.

    Raised when a requested plugin file does not exist.
    """



class PluginMetadataError(PluginError):
    """
    Plugin metadata is invalid or missing.

    Raised when:
    - Required metadata header is missing (long_name, description, priority)
    - Metadata value is invalid (priority out of range, etc.)
    - Metadata cannot be parsed
    """



class PluginExecutionError(PluginError):
    """
    Plugin execution failed.

    Raised when:
    - Plugin crashes or returns unexpected error
    - Plugin process cannot be started
    - Plugin has syntax errors
    """



class PluginTimeoutError(PluginError):
    """
    Plugin execution timed out.

    Raised when a plugin takes longer than the configured timeout
    to complete execution.
    """



class ExtensionError(RisuError):
    """
    Extension loading or execution error.

    Raised when:
    - Extension module cannot be loaded
    - Extension init() fails
    - Extension is missing required methods
    """



class ExtensionNotFoundError(ExtensionError):
    """
    Extension not found.

    Raised when a requested extension does not exist.
    """



class HookError(RisuError):
    """
    Hook execution error.

    Raised when a hook fails to execute or returns an error.
    """



class OutputError(RisuError):
    """
    Output generation error.

    Raised when:
    - Cannot write to output file
    - JSON serialization fails
    - Web output generation fails
    """



class ValidationError(RisuError):
    """
    Validation error.

    Raised when validation of plugins, metadata, or other
    components fails.
    """

