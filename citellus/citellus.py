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
import datetime
import gettext
import json
import logging
import os
import subprocess
import sys
import traceback
from multiprocessing import Pool, cpu_count

LOG = logging.getLogger('citellus')

# Where are we?
citellusdir = os.path.abspath(os.path.dirname(__file__))
localedir = os.path.join(citellusdir, 'locale')

trad = gettext.translation('citellus', localedir, fallback=True)

try:
    _ = trad.ugettext
except AttributeError:
    _ = trad.gettext

RC_OKAY = 0
RC_FAILED = 1
RC_SKIPPED = 2

DEFAULT_PLUGIN_PATH = ['plugins']

class bcolors:
    black = '\033[30m'
    failed = red = '\033[31m'
    green = '\033[32m'
    orange = '\033[33m'
    blue = '\033[34m'
    magenta = purple = '\033[35m'
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


def colorize(text, color, stream=sys.stdout, force=False):
    if not force and (not hasattr(stream, 'isatty') or not stream.isatty()):
        return text

    color = getattr(bcolors, color)

    return '{color}{text}{reset}'.format(
        color=color, text=text, reset=bcolors.end)


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


def findplugins(folders, include=None, exclude=None):
    """
    Finds plugins in path and returns array of them
    :param filters: Defines array of filters to match against plugin path/name
    :param folders: Folders to use as source for plugin search
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

    if include:
        plugins = [plugin for plugin in plugins
                   for filter in include
                   if filter in plugin]

    if exclude:
        plugins = [plugin for plugin in plugins
                   for filter in exclude
                   if filter not in plugin]

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

    return {'plugin': plugin,
            'result': {"rc": returncode,
                       "out": out.decode('ascii', 'ignore'),
                       "err": err.decode('ascii', 'ignore')}}


def docitellus(live=False, path=False, plugins=False):
    """
    Runs citellus scripts on specified root folder
    :param path: Path to analyze
    :param live:  Test is to be executed live or on snapshot/sosreport
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

    return results


def formattext(returncode):
    """
    Returns print formating for return code
    :param returncode: return code of plugin
    :return: formatted text for printing
    """
    colors = [
        ('okay', 'green'),
        ('failed', 'red'),
        ('skipped', 'cyan'),
    ]

    try:
        selected = colors[returncode]
    except:
        selected = ('unknown', 'magenta')

    return colorize(*selected)


def indent(text, amount):
    padding = ' ' * amount
    return '\n'.join(padding+line for line in text.splitlines())


def parse_args():
    """
    Parses arguments on commandline
    :return: parsed arguments
    """

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
    p.add_argument("--output", "-o",
                   metavar="FILENAME",
                   help=_("Write results to JSON file FILENAME"))
    p.add_argument("--list-plugins",
                   action="store_true",
                   help=_("Print a list of discovered plugins and exit"))

    g = p.add_argument_group('Filtering options')
    g.add_argument("-i", "--include",
                   metavar='SUBSTRING',
                   help=_("Only include plugins that contain substring"),
                   default=[],
                   action='append')
    g.add_argument("-x", "--exclude",
                   metavar='SUBSTRING',
                   help=_("Exclude plugins that contain substring"),
                   default=[],
                   action='append')

    p.add_argument('plugin_path', nargs='*')

    return p.parse_args()


def write_results(results, filename,
                  live=False, path=None):
    data = {
        'metadata': {
            'when': datetime.datetime.utcnow().isoformat(),
            'live': bool(live),
        },
        'results': sorted(results, key=lambda r: r['plugin']),
    }

    if path:
        data['metadata']['path'] = path

    with open(filename, 'w') as fd:
        json.dump(data, fd, indent=2)


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
        LOG.info('using default plugin path %s', DEFAULT_PLUGIN_PATH)
        options.plugin_path = DEFAULT_PLUGIN_PATH

    # Find available plugins
    plugins = findplugins(options.plugin_path,
                          include=options.include,
                          exclude=options.exclude)

    if options.list_plugins:
        print("\n".join(plugins))
        return

    if not options.silent:
        show_logo()
        print(_("found #%s tests at %s") % (len(plugins), ", ".join(options.plugin_path)))

    if not plugins:
        LOG.error(_("did not discover any plugins, exiting"))
        sys.exit(1)

    if not options.silent:
        if options.live:
            print(_("mode: live"))
        else:
            print(_("mode: fs snapshot %s" % CITELLUS_ROOT))

    # Execute runplugin for each plugin found
    results = docitellus(live=options.live, path=CITELLUS_ROOT, plugins=plugins)

    if options.output:
        write_results(results, options.output,
                      live=options.live,
                      path=CITELLUS_ROOT)

    # Print results based on the sorted order based on returned results from
    # parallel execution
    for result in sorted(results, key=lambda r: r['plugin']):
        out = result['result']['out']
        err = result['result']['err']
        rc = result['result']['rc']
        text = formattext(rc)

        print("# %s: %s" % (result['plugin'], text))

        show_err = (
            (rc in [RC_FAILED])
            or (rc not in [RC_OKAY, RC_FAILED, RC_SKIPPED])
            or (rc in [RC_SKIPPED] and options.verbose > 0)
            or (options.verbose > 1)
        )

        show_out = (
            options.verbose > 1
        )

        if show_out and out.strip():
            print(indent(out, 4))

        if show_err and err.strip():
            print(indent(err, 4))

if __name__ == "__main__":
    main()
