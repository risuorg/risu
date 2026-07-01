#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Description: Plugin execution with multiprocessing for Risu
# Copyright (C) 2026 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

"""
Plugin execution engine.

This module handles parallel execution of plugins using multiprocessing
with proper resource management and error handling.
"""

from __future__ import print_function

import logging
import multiprocessing
import signal
import sys

# Python 2.7 compatible context manager
try:
    from contextlib import closing
except ImportError:
    # Fallback for very old Python
    class closing(object):
        def __init__(self, thing):
            self.thing = thing

        def __enter__(self):
            return self.thing

        def __exit__(self, *exc_info):
            try:
                self.thing.close()
            except AttributeError:
                pass


LOG = logging.getLogger("risu.executor")


class PluginExecutor(object):
    """
    Parallel plugin executor using multiprocessing.

    Provides safe concurrent execution of plugins with proper
    resource cleanup and interrupt handling.

    Attributes:
        num_processes (int): Number of worker processes
        timeout (int): Plugin execution timeout in seconds
    """

    def __init__(self, num_processes=None, timeout=30):
        """
        Initialize plugin executor.

        Args:
            num_processes (int, optional): Number of workers. If None,
                                          uses CPU count
            timeout (int): Plugin timeout in seconds (default: 30)
        """
        if num_processes is None:
            try:
                num_processes = multiprocessing.cpu_count()
            except NotImplementedError:
                num_processes = 1

        self.num_processes = num_processes
        self.timeout = timeout

        LOG.debug(
            "PluginExecutor initialized with %d processes, %d second timeout",
            self.num_processes,
            self.timeout,
        )

    def execute_plugins(self, plugins, execute_func, progress_callback=None):
        """
        Execute plugins in parallel.

        Args:
            plugins (list): List of plugin dictionaries to execute
            execute_func (callable): Function to execute for each plugin.
                                    Should take plugin dict and return result dict.
            progress_callback (callable, optional): Called after each plugin
                                                   with (plugin, result)

        Returns:
            list: List of result dictionaries in same order as input plugins

        Raises:
            KeyboardInterrupt: If user interrupts execution
            Exception: If critical error occurs

        Example:
            >>> def run_plugin(plugin):
            ...     return {'rc': 10, 'out': '', 'err': ''}
            >>> executor = PluginExecutor(num_processes=4)
            >>> results = executor.execute_plugins(plugins, run_plugin)
        """
        if not plugins:
            LOG.debug("No plugins to execute")
            return []

        total = len(plugins)
        LOG.info("Executing %d plugins with %d workers", total, self.num_processes)

        # Limit workers to number of plugins
        num_workers = min(self.num_processes, total)

        results = []

        try:
            # Use context manager for proper cleanup
            with closing(multiprocessing.Pool(num_workers)) as pool:
                try:
                    # Execute plugins asynchronously
                    async_results = [
                        pool.apply_async(execute_func, (plugin,)) for plugin in plugins
                    ]

                    # Collect results
                    for i, async_result in enumerate(async_results):
                        try:
                            result = async_result.get(timeout=self.timeout + 10)
                            results.append(result)

                            # Call progress callback
                            if progress_callback:
                                progress_callback(plugins[i], result)

                        except multiprocessing.TimeoutError:
                            LOG.error("Plugin timed out: %s", plugins[i].get("plugin"))
                            results.append(
                                {
                                    "rc": 3,
                                    "out": "",
                                    "err": "Plugin execution timed out",
                                    "plugin": plugins[i].get("plugin"),
                                }
                            )

                        except Exception as e:
                            LOG.error(
                                "Plugin execution failed: %s - %s",
                                plugins[i].get("plugin"),
                                str(e),
                            )
                            results.append(
                                {
                                    "rc": 3,
                                    "out": "",
                                    "err": "Plugin execution error: %s" % str(e),
                                    "plugin": plugins[i].get("plugin"),
                                }
                            )

                except KeyboardInterrupt:
                    LOG.warning("Interrupted by user, terminating workers...")
                    pool.terminate()
                    raise

                finally:
                    # Ensure pool is properly closed
                    pool.close()
                    pool.join()

        except KeyboardInterrupt:
            LOG.warning("Execution interrupted by user")
            raise

        LOG.info("Completed executing %d plugins", total)
        return results

    def execute_plugins_serial(self, plugins, execute_func, progress_callback=None):
        """
        Execute plugins serially (no multiprocessing).

        Useful for debugging or when multiprocessing causes issues.

        Args:
            plugins (list): List of plugin dictionaries
            execute_func (callable): Execution function
            progress_callback (callable, optional): Progress callback

        Returns:
            list: List of result dictionaries
        """
        if not plugins:
            return []

        LOG.info("Executing %d plugins serially", len(plugins))

        results = []
        for plugin in plugins:
            try:
                result = execute_func(plugin)
                results.append(result)

                if progress_callback:
                    progress_callback(plugin, result)

            except KeyboardInterrupt:
                LOG.warning("Interrupted by user")
                raise

            except Exception as e:
                LOG.error(
                    "Plugin execution failed: %s - %s", plugin.get("plugin"), str(e)
                )
                results.append(
                    {
                        "rc": 3,
                        "out": "",
                        "err": "Plugin execution error: %s" % str(e),
                        "plugin": plugin.get("plugin"),
                    }
                )

        return results


def execute_with_timeout(func, args=(), kwargs=None, timeout=30):
    """
    Execute function with timeout (Python 2.7 compatible).

    Uses multiprocessing to enforce timeout. This is a standalone
    function that doesn't require PluginExecutor.

    Args:
        func (callable): Function to execute
        args (tuple): Positional arguments for func
        kwargs (dict, optional): Keyword arguments for func
        timeout (int): Timeout in seconds

    Returns:
        Result of func() if successful

    Raises:
        TimeoutError: If function exceeds timeout (Python 3)
        multiprocessing.TimeoutError: If function exceeds timeout (Python 2.7)
        Exception: If function raises exception

    Example:
        >>> result = execute_with_timeout(expensive_function, args=(arg1,), timeout=10)
    """
    if kwargs is None:
        kwargs = {}

    # Create a pool with single worker
    pool = multiprocessing.Pool(1)

    try:
        async_result = pool.apply_async(func, args, kwargs)

        # Wait for result with timeout
        result = async_result.get(timeout=timeout)

        return result

    finally:
        pool.terminate()
        pool.join()


# Signal handler for graceful shutdown
_original_sigint_handler = None


def _install_signal_handlers():
    """
    Install signal handlers for graceful shutdown.

    Stores original SIGINT handler so it can be restored.
    """
    global _original_sigint_handler

    def sigint_handler(signum, frame):
        """Handle SIGINT (Ctrl+C) gracefully."""
        LOG.warning("Received SIGINT, shutting down...")
        # Restore original handler
        if _original_sigint_handler:
            signal.signal(signal.SIGINT, _original_sigint_handler)
        # Re-raise KeyboardInterrupt
        raise KeyboardInterrupt()

    _original_sigint_handler = signal.signal(signal.SIGINT, sigint_handler)


def _restore_signal_handlers():
    """Restore original signal handlers."""
    global _original_sigint_handler
    if _original_sigint_handler:
        signal.signal(signal.SIGINT, _original_sigint_handler)
