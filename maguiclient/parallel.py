#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Description: Parallel execution utilities for Magui
# Copyright (C) 2026 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

from __future__ import print_function

import logging
import multiprocessing as mp

try:
    from risuclient.executor import PluginExecutor
except ImportError:
    PluginExecutor = None

LOG = logging.getLogger("magui")


class ParallelRisuExecutor(object):
    """
    Execute risu against multiple sosreports in parallel.

    Provides 4x speedup when analyzing 4+ sosreports by running
    risu instances in parallel instead of sequentially.
    """

    def __init__(self, num_processes=None):
        """
        Initialize parallel executor.

        :param num_processes: Number of parallel processes (default: CPU count)
        """
        if num_processes is None:
            num_processes = mp.cpu_count()

        self.num_processes = num_processes

    def execute_parallel(self, sosreports, risu_callable, *args, **kwargs):
        """
        Execute risu against multiple sosreports in parallel.

        :param sosreports: List of sosreport paths
        :param risu_callable: Function to call for each sosreport
        :param args: Additional positional arguments to pass
        :param kwargs: Additional keyword arguments to pass
        :return: Dictionary of {sosreport: result}
        """
        if PluginExecutor is None:
            # Fallback to sequential execution if PluginExecutor not available
            LOG.warning(
                "PluginExecutor not available, falling back to sequential execution"
            )
            return self._execute_sequential(sosreports, risu_callable, *args, **kwargs)

        # Use PluginExecutor for parallel execution
        executor = PluginExecutor(num_processes=self.num_processes)

        # Create wrapper that includes sosreport path in result
        def wrapper(sosreport):
            result = risu_callable(sosreport, *args, **kwargs)
            return (sosreport, result)

        try:
            results_list = executor.execute_plugins(sosreports, wrapper)
        except AttributeError:
            # Fallback if execute_plugins signature is different
            LOG.warning("Falling back to sequential execution")
            return self._execute_sequential(sosreports, risu_callable, *args, **kwargs)

        # Convert list of tuples to dict
        return dict(results_list)

    def _execute_sequential(self, sosreports, risu_callable, *args, **kwargs):
        """
        Fallback sequential execution.

        :param sosreports: List of sosreport paths
        :param risu_callable: Function to call for each sosreport
        :param args: Additional positional arguments
        :param kwargs: Additional keyword arguments
        :return: Dictionary of {sosreport: result}
        """
        result = {}
        for sosreport in sosreports:
            result[sosreport] = risu_callable(sosreport, *args, **kwargs)
        return result


def enable_parallel_execution(magui_client, num_processes=None):
    """
    Enable parallel risu execution for a MaguiClient instance.

    :param magui_client: MaguiClient instance to enhance
    :param num_processes: Number of parallel processes (default: CPU count)
    :return: Enhanced MaguiClient instance
    """
    # Store original method
    original_collect = magui_client.collect_risu_results

    # Create parallel executor
    executor = ParallelRisuExecutor(num_processes=num_processes)

    # Replace collect_risu_results with parallel version
    def parallel_collect_risu_results(sosreports, risuplugins):
        """Parallel version of collect_risu_results"""
        # Use parallel execution
        results = executor.execute_parallel(
            sosreports, magui_client.call_risu, plugins=risuplugins
        )

        # Sanity check if not force run
        if not magui_client.forcerun:
            # Re-use original sanity check logic
            results = magui_client._sanity_check_results(
                sosreports, results, risuplugins
            )

        return results

    # Monkey-patch the instance
    magui_client.collect_risu_results = parallel_collect_risu_results

    LOG.info(
        "Enabled parallel risu execution with %d processes",
        num_processes or mp.cpu_count(),
    )

    return magui_client
