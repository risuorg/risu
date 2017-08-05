#!/usr/bin/env python
# encoding: utf-8
#
# Description: Runs set of scripts against system or snapshot to
#              detect common pitfalls in configuration/status
#
# Copyright (C) 2017 Robin Černín (rcernin@redhat.com)
#                    Lars Kellogg-Stedman <lars@redhat.com>
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

from __future__ import print_function

import argparse
import gettext
import logging
import os
import os.path
import subprocess
import sys
import traceback
from multiprocessing import Pool, cpu_count

LOG = logging.getLogger('citellus')

# Where are we?
citellusdir = os.path.abspath(os.path.dirname(__file__))
localedir = os.path.join(citellusdir, 'locale')

trad = gettext.translation('citellus', localedir, fallback=True)
_ = trad.ugettext


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
    print("\n".join(logo))


def findplugins(folders=[], filters=[]):
    """
    Finds plugins in path and returns array of them
    :param folders: Folders to use as source for plugin search
    :param filter: Filter to apply to plugins
    :return:
    """

    LOG.debug('starting plugin search in: %s', folders)

    plugins = []
    for folder in folders:
        for root, dirnames, filenames in os.walk(folder):
            LOG.debug('looking for plugins in: %s', root)
            for filename in filenames:
                filepath = os.path.join(root, filename)
                LOG.debug('considering: %s', filepath)
                if os.access(filepath, os.X_OK):
                    plugins.append(filepath)

    LOG.debug(msg=_('Found plugins: %s') % plugins)

    if filters:
        plugins = [ plugin for plugin in plugins for filter in filters
                   if filter in plugin ]

    # this unique-ifies the list of plugins (and ensures consistent
    # ordering).
    return sorted(set(plugins))


def runplugin(plugin):
    """
    Runs provided plugin and outputs message
    :param plugin:  plugin to execute
    :return: result, out, err
    """

    LOG.debug(msg=_('Running plugin: %s') % plugin)
    try:
        p = subprocess.Popen(plugin, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        out, err = p.communicate()
        returncode = p.returncode
    except:
        returncode = 3
        out = ""
        err = traceback.format_exc()

    return {'plugin': plugin, 'output': {"rc": returncode, "out": out, "err": err}}


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

    LOG.debug(msg=_("Plugins executed for %s: %s with result: %s") % (path, plugins, new_dict))

    return new_dict


def formattext(returncode):
    """
    Returns print formating for return code
    :param returncode: return code of plugin
    :return: formatted text for printing
    """
    colors = [bcolors.okay, bcolors.failed, bcolors.skipped, bcolors.unexpected]
    return colors[returncode]


def parse_args():
    description = _(
        'Citellus allows to analyze a directory against common set of tests, useful for finding common configuration errors')

    # Option parsing
    p = argparse.ArgumentParser("citellus.py [arguments]", description=description)
    p.add_argument("-l", "--live",
                   help=_("Work on a live system instead of a snapshot"),
                   action='store_true')
    p.add_argument("-v", "--verbose",
                   help=_("Execute in verbose mode"),
                   default=False,
                   action='store_true')
    p.add_argument('-d', "--loglevel",
                   help=_("Set log level"),
                   default="info",
                   type=lambda x: x.upper(),
                   choices=["INFO", "DEBUG", "WARNING", "ERROR", "CRITICAL"])
    p.add_argument("-s", "--silent",
                   help=_("Enable silent mode, only errors on tests written"),
                   action='store_true')
    p.add_argument("-f", "--filter",
                   help=_("Only include plugins that contains in full path that substring"),
                   default=[],
                   action='append')
    p.add_argument("--list-plugins",
                   action="store_true",
                   help=_("Print a list of discovered plugins and exit"))

    p.add_argument('plugin_path', nargs='*')

    return p.parse_args()


def main():
    """
    Main function for the program
    :return: none
    """

    options = parse_args()

    # Configure logging
    logging.basicConfig(level=options.loglevel)

    if not options.live:
        if len(options.plugin_path) > 0:
            # Live not specified, so we will use file snapshot as first arg and remaining cli arguments as plugins
            CITELLUS_ROOT = options.plugin_path.pop(0)
        else:
            LOG.error(_("When not running in Live mode, snapshot path is required"))
            sys.exit(1)
    else:
        CITELLUS_ROOT = ""

    if not options.plugin_path:
        LOG.debug('using default plugin path')
        options.plugin_path = ['plugins']

    # Find available plugins
    plugins = findplugins(folders=options.plugin_path, filters=options.filter)

    if options.list_plugins:
        print("\n".join(plugins))
        return

    if not options.silent:
        show_logo()
        print(_("found #%s tests at %s") % (len(plugins), ", ".join(options.plugin_path)))

    if not plugins:
        LOG.error(_("Plugin folder empty, exitting"))
        sys.exit(1)

    if not options.silent:
        if options.live:
            print(_("mode: live"))
        else:
            print(_("mode: fs snapshot %s" % CITELLUS_ROOT))

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

        # We don't print stdout
        # out = plugin['output']['out']
        err = plugin['output']['err']
        rc = plugin['output']['rc']
        text = formattext(returncode=rc)

        # If not standard RC, print stderr
        if (rc != 0 and rc != 2) or (options.verbose and rc == 2):
            print("# %s: %s" % (plugin['plugin'], text))
            if err != "":
                for line in err.split('\n'):
                    print("    %s" % line)
        else:
            if 'okay' in text:
                okay.append(plugin['plugin'].replace(common, ''))
            if 'skipped' in text:
                skipped.append(plugin['plugin'].replace(common, ''))

        LOG.debug(msg=_("Plugin: %s, output: %s") % (plugin['plugin'], plugin['output']))

    if not options.silent:
        if okay:
            print("# %s: %s" % (okay, bcolors.okay))
        if skipped:
            print("# %s: %s" % (skipped, bcolors.skipped))


if __name__ == "__main__":
    main()
