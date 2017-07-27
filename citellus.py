#!/usr/bin/env python
# encoding: utf-8
#
# Description: Runs set of scripts against system or snapshot to
#              detect common pitfalls in configuration/status
#
# Copyright (C) 2017 Robin Černín (rcernin@redhat.com)
#                    Lars Kellogg-Stedman <lars@oddbit.com>
#                    Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

import argparse
import gettext
import logging
import os
import os.path
import subprocess
import sys
import traceback
from multiprocessing import Pool, cpu_count

# Where are we?
citellusdir = os.path.abspath(os.path.dirname(__file__))
localedir = os.path.join(citellusdir, 'locale')

trad = gettext.translation('citellus', localedir, fallback=True)
_ = trad.ugettext


# Implement switch from http://code.activestate.com/recipes/410692/
class Switch(object):
    """
    Defines a class that can be used easily as traditional switch commands
    """

    def __init__(self, value):
        self.value = value
        self.fall = False

    def __iter__(self):
        """Return the match method once, then stop"""
        yield self.match
        raise StopIteration

    def match(self, *args):
        """Indicate whether or not to enter a case suite"""
        if self.fall or not args:
            return True
        elif self.value in args:  # changed for v1.5, see below
            self.fall = True
            return True
        else:
            return False


def conflogging(verbosity=False):
    """
    This function configures the logging handlers for console and file
    """

    # Define logging settings
    for case in Switch(verbosity):
        # choices=["info", "debug", "warn", "critical"])
        if case('debug'):
            level = logging.DEBUG
            break
        if case('critical'):
            level = logging.CRITICAL
            break
        if case('warn'):
            level = logging.WARN
            break
        if case('info'):
            level = logging.INFO
            break
        if case():
            # Default to DEBUG log level
            level = logging.INFO

    return level


class bcolors:
    black = '\033[30m'
    red = '\033[31m'
    green = '\033[32m'
    orange = '\033[33m'
    blue = '\033[34m'
    purple = '\033[35m'
    cyan = '\033[36m'
    lightgrey = '\033[37m'
    darkgrey = '\033[90m'
    lightred = '\033[91m'
    lightgreen = '\033[92m'
    yellow = '\033[93m'
    lightblue = '\033[94m'
    pink = '\033[95m'
    lightcyan = '\033[96m'
    end = '\033[0m'
    okay = green + _("okay") + end
    failed = red + _("failed") + end
    skipped = orange + _("skipped") + end
    unexpected = red + _("unexpected result") + end


def show_logo():
    """
    Prints citellus Logo
    :return:
    """

    logo = "_________ .__  __         .__  .__                ", \
           "\_   ___ \|__|/  |_  ____ |  | |  |  __ __  ______", \
           "/    \  \/|  \   __\/ __ \|  | |  | |  |  \/  ___/", \
           "\     \___|  ||  | \  ___/|  |_|  |_|  |  /\___ \ ", \
           " \______  /__||__|  \___  >____/____/____//____  >", \
           "        \/              \/                     \/ "
    for line in logo:
        print line


def findplugins(folders=[], filter=False):
    """
    Finds plugins in path and returns array of them
    :param folders: Folders to use as source for plugin search
    :param filter: Filter to apply to plugins
    :return:
    """

    logger = logging.getLogger(__name__)

    # If folders is empty, use default path
    if folders == []:
        folders = [os.path.join(citellusdir, 'plugins')]

    plugins = []
    for folder in folders:
        for root, dir, files in os.walk(folder):
            for file in files:
                script = os.path.join(folder, file)
                if os.access(script, os.X_OK):
                    plugins.append(script)
            for subfolder in dir:
                # Find new plugins in the folder but do not filter as we'll do that later
                plugins.extend(findplugins(folders=[os.path.join(folder, subfolder)]))
    logger.debug(msg=_('Found plugins: %s') % plugins)

    # Remove lists of lists with getitems and duplicates with set
    candidates = list(set(getitems(plugins)))
    if filter:
        logger.debug(msg=_('Filtering of plugins enabled for: %s') % filter)
        plugins = []
        for plugin in candidates:
            if filter in plugin:
                plugins.append(plugin)
            else:
                logger.debug(msg=_('Plugin %s does not pass filter') % plugin)
    else:
        # No filtering, return list
        plugins = candidates

    return plugins


def runplugin(plugin):
    """
    Runs provided plugin and outputs message
    :param plugin:  plugin to execute
    :return: result, out, err
    """

    logger = logging.getLogger(__name__)

    logger.debug(msg=_('Running plugin: %s') % plugin)
    try:
        p = subprocess.Popen(plugin, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        out, err = p.communicate()
        returncode = p.returncode
    except:
        returncode = 3
        out = ""
        err = traceback.format_exc()

    for case in Switch(returncode):
        if case(0):
            # OK
            text = bcolors.okay
            break
        if case(1):
            # FAILED
            text = bcolors.failed
            break
        if case(2):
            # SKIPPED
            text = bcolors.skipped
            break
        if case():
            # UNEXPECTED
            text = bcolors.unexpected
            break

    return {'plugin': plugin, 'output': {"rc": returncode, "out": out, "err": err, "text": text}}


def getitems(var):
    """
    Returns list of items even if provided args are lists of lists
    :param var: list or value to pass
    :return: unique list of values
    """

    logger = logging.getLogger(__name__)

    result = []
    if not isinstance(var, list):
        result.append(var)
    else:
        for elem in var:
            result.extend(getitems(elem))

    # Do cleanup of duplicates
    final = []
    for elem in result:
        if elem not in final:
            final.append(elem)

    # As we call recursively, don't log calls for just one ID
    if len(final) > 1:
        logger.debug(msg=_("Final deduplicated list: %s") % final)
    return final


def commonpath(folders):
    commonroot = []
    ls = [p.split('/') for p in folders]
    minlenght = min(len(p) for p in ls)

    for i in range(minlenght):
        s = set(p[i] for p in ls)
        if len(s) != 1:
            break
        commonroot.append(s.pop())

    return '/'.join(commonroot)


def docitellus(live=False, path=False, plugins=False):
    """
    Runs citellus scripts on specified root folder
    :param live:  Test is to be executed live or on snapshot/sosreport
    :param CITELLUS_ROOT: Path for non live access
    :param plugins:  plugins to execute against the system
    :return: Dict of plugins and results
    """
    logger = logging.getLogger(__name__)
    # Enable LIVE mode if parameter passed
    if live:
        CITELLUS_LIVE = 1
    else:
        CITELLUS_LIVE = 0

    # Save environment variables for plugins executed
    os.environ['CITELLUS_ROOT'] = "%s" % path
    os.environ['CITELLUS_LIVE'] = "%s" % CITELLUS_LIVE
    os.environ['LANG'] = "%s" % "C"

    # Set pool for same processes as CPU cores
    p = Pool(cpu_count())

    # Execute runplugin for each plugin found
    results = p.map(runplugin, plugins)

    # Process plugin output from multiple plugins for result printing
    new_dict = {}
    for item in results:
        name = item['plugin']
        new_dict[name] = item

    return new_dict


def main():
    """
    Main function for the program
    :return: none
    """

    description = _(
        'Citellus allows to analyze a directory against common set of tests, useful for finding common configuration errors')

    # Option parsing
    p = argparse.ArgumentParser("citellus.py [arguments]", description=description)
    p.add_argument("-l", "--live", dest="live", help=_("Work on a live system instead of a snapshot"), default=False,
                   action='store_true')
    p.add_argument("-v", "--verbose", dest="verbose", help=_("Execute in verbose mode"), default=False,
                   action='store_true')
    p.add_argument('-d', "--verbosity", dest="verbosity",
                   help=_("Set verbosity level for messages while running/logging"),
                   default="info", choices=["info", "debug", "warn", "critical"])
    p.add_argument("-s", "--silent", dest="silent", help=_("Enable silent mode, only errors on tests written"), default=False,
                   action='store_true')
    p.add_argument("-f", "--filter", dest="filter", help=_("Only include plugins that contains in full path that substring"),
                   default=False)

    options, unknown = p.parse_known_args()

    # Configure logging
    logging.basicConfig(level=conflogging(verbosity=options.verbosity))

    # Prepare our logger
    logger = logging.getLogger(__name__)

    logger.debug(msg=_('Additional parameters: %s') % unknown)

    if not options.live:
        if len(unknown) > 0:
            # Live not specified, so we will use file snapshot as first arg and remaining cli arguments as plugins
            CITELLUS_ROOT = unknown[0]
            start = 1
        else:
            print _("When not running in Live mode, snapshot path is required")
            sys.exit(1)
    else:
        CITELLUS_ROOT = ""
        start = 0

    plugin_path = []
    if len(unknown) > start:
        # We've more parameters defined, so they are for plugin paths

        for path in unknown[start:]:
            plugin_path.append(path)

    # Find available plugins
    plugins = findplugins(folders=plugin_path, filter=options.filter)

    if not options.silent:
        show_logo()
        print _("found #%s tests at %s") % (len(plugins), ", ".join(plugin_path))

    if not plugins:
        msg = _("Plugin folder empty, exitting")
        logger.debug(msg=msg)
        print msg
        sys.exit(1)

    if not options.silent:
        if options.live:
            print _("mode: live")
        else:
            print _("mode: fs snapshot %s" % CITELLUS_ROOT)

    # Set pool for same processes as CPU cores
    p = Pool(cpu_count())

    # Execute runplugin for each plugin found
    new_dict = docitellus(live=options.live, path=CITELLUS_ROOT, plugins=plugins)

    # Sort plugins based on path name
    std = sorted(plugins, key=lambda file: (os.path.dirname(file), os.path.basename(file)))

    # Common path for plugins
    if len(plugins) > 1:
        common = commonpath(plugins)
    else:
        common = ""

    # Print results based on the sorted order based on returned results from parallel execution
    okay = []
    skipped = []
    for i in range(0, len(std)):
        plugin = new_dict[std[i]]

        out = plugin['output']['out']
        err = plugin['output']['err']
        text = plugin['output']['text']
        rc = plugin['output']['rc']

        # If not standard RC, print stderr
        if (rc != 0 and rc != 2) or (options.verbose and rc == 2):
            print "# %s: %s" % (plugin['plugin'], text)
            if err != "":
                for line in err.split('\n'):
                    print "    %s" % line
        else:
            if 'okay' in text:
                okay.append(plugin['plugin'].replace(common, ''))
            if 'skipped' in text:
                skipped.append(plugin['plugin'].replace(common, ''))

        logger.debug(msg=_("Plugin: %s, output: %s") % (plugin['plugin'], plugin['output']))

    if not options.silent:
        if okay:
            print "# %s: %s" % (okay, bcolors.okay)
        if skipped:
            print "# %s: %s" % (skipped, bcolors.skipped)


if __name__ == "__main__":
    main()
