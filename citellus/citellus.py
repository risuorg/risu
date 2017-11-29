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
import time
import json
import logging
import os
import re
import subprocess
import sys
import traceback
import exts
from multiprocessing import Pool, cpu_count

global extensions
extensions = []

LOG = logging.getLogger('citellus')

# Where are we?
citellusdir = os.path.abspath(os.path.dirname(__file__))
localedir = os.path.join(citellusdir, 'locale')

# This will use system defined LANGUAGE
trad = gettext.translation('citellus', localedir, fallback=True)

try:
    _ = trad.ugettext
except AttributeError:
    _ = trad.gettext

# Return codes to use (not to mask bash or other and catch other errors)
RC_OKAY = 10
RC_FAILED = 20
RC_SKIPPED = 30


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
           "        \/              \/                     \/ ", \
           _("                                                  ")
    print("\n".join(logo))


def findplugins(folders, include=None, exclude=None, executables=True):
    """
    Finds plugins in path and returns array of them
    :param filters: Defines array of filters to match against plugin path/name
    :param folders: Folders to use as source for plugin search
    :return:
    """

    if not folders:
        folders = [os.path.join(citellusdir, 'plugins')]

    LOG.debug('starting plugin search in: %s', folders)

    plugins = []
    for folder in folders:
        for root, dirnames, filenames in os.walk(folder):
            LOG.debug('looking for plugins in: %s', root)
            for filename in filenames:
                filepath = os.path.join(root, filename)
                LOG.debug('considering: %s', filepath)
                if executables:
                    if os.access(filepath, os.X_OK):
                        plugins.append(filepath)
                else:
                    plugins.append(filepath)

    if include:
        plugins = [plugin for plugin in plugins
                   for filter in include
                   if filter in plugin]

    if exclude:
        plugins = [plugin for plugin in plugins
                   if not any(filter in plugin for filter in exclude)]

    LOG.debug(msg=_('Found plugins: %s') % plugins)

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
    start_time = time.clock()

    try:
        os.environ['PLUGIN_BASEDIR'] = "%s" % os.path.abspath(os.path.dirname(plugin))
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
                       "err": err.decode('ascii', 'ignore')},
            'time': time.clock() - start_time}


def docitellus(live=False, path=False, plugins=False, lang='en_US'):
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
    os.environ['CITELLUS_BASE'] = "%s" % citellusdir
    os.environ['LANG'] = "%s" % lang
    os.environ['RC_OKAY'] = "%s" % RC_OKAY
    os.environ['RC_FAILED'] = "%s" % RC_FAILED
    os.environ['RC_SKIPPED'] = "%s" % RC_SKIPPED
    os.environ['TEXTDOMAIN'] = 'citellus'
    os.environ['TEXTDOMAINDIR'] = "%s/locale" % citellusdir

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
    colors = {
        RC_OKAY: ('okay', 'green'),
        RC_FAILED: ('failed', 'red'),
        RC_SKIPPED: ('skipped', 'cyan')
    }

    try:
        selected = colors[returncode]
    except:
        selected = ('unknown', 'magenta')

    return colorize(*selected)


def indent(text, amount):
    """
    Idents text by amount
    :param text:  text to ident
    :param amount:  spaces to use
    :return:
    """
    padding = ' ' * amount
    return '\n'.join(padding + line for line in text.splitlines())


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
    p.add_argument("--list-plugins",
                   action="store_true",
                   help=_("Print a list of discovered plugins and exit"))
    p.add_argument("--description",
                   action="store_true",
                   help=_("With list-plugins, also outputs plugin description"))
    p.add_argument("--output", "-o",
                   metavar="FILENAME",
                   help=_("Write results to JSON file FILENAME"))

    g = p.add_argument_group('Output and logging options')
    g.add_argument("--blame",
                   action="store_true",
                   help=_("Report time spent on each plugin"),
                   default=False)
    g.add_argument("--lang",
                   action="store_true",
                   help=_("Define locale to use"),
                   default='en_US')
    g.add_argument("--only-failed", "-F",
                   action="store_true",
                   help=_("Only show failed tests"))
    g.add_argument("-v", "--verbose",
                   help=_("Increase verbosity of output (may be "
                          "specified more than once)"),
                   default=0,
                   action='count')
    g.add_argument('-d', "--loglevel",
                   help=_("Set log level"),
                   default="info",
                   type=lambda x: x.upper(),
                   choices=["INFO", "DEBUG", "WARNING", "ERROR", "CRITICAL"])
    g.add_argument("-q", "--quiet",
                   help=_("Enable quiet mode"),
                   action='store_true')

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
    """
    Writes result
    :param results: Data to write
    :param filename: File to use
    :param live: Metadata
    :param path: Path to write to file metadata
    :return:
    """
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


def get_description(plugin=False):
    """
    Gets description for provided plugin
    :param plugin:  plugin
    :return: Description text
    """

    regexp = '\A# description:'
    description = False
    with open(plugin, 'r') as f:
        for line in f:
            if re.match(regexp, line):
                description = line

    return description


def main():
    """
    Main function for the program
    :return: none
    """

    start_time = time.clock()

    options = parse_args()

    global _

    # Configure ENV language before anything else
    os.environ['LANG'] = "%s" % options.lang

    # Configure logging
    logging.basicConfig(level=options.loglevel)

    if not options.live:
        if len(options.plugin_path) > 0:
            # Live not specified, so we will use file snapshot as first arg and remaining cli arguments as plugins
            CITELLUS_ROOT = options.plugin_path.pop(0)
        elif not options.list_plugins:
            LOG.error(_("When not running in Live mode, snapshot path is required"))
            sys.exit(1)
    else:
        CITELLUS_ROOT = ""

    if not options.plugin_path:
        LOG.info('using default plugin path')

    # Find available plugins
    plugins = findplugins(options.plugin_path,
                          include=options.include,
                          exclude=options.exclude)

    # Process Citellus extensions
    global extensions
    extensions = exts.initExtensions()

    if options.list_plugins:
        for each in plugins:
            print(each)
            if options.description:
                desc = get_description(plugin=each)
                if desc:
                    print(desc)
        for each in extensions:
            print("#PYEXT: %s" % each.__name__.split(".")[-1])
            if options.description:
                desc = each.help()
                if desc:
                    print(desc)
        return

    # Reinstall language in case it has changed
    trad = gettext.translation('citellus', localedir, fallback=True, languages=[options.lang])

    try:
        _ = trad.ugettext
    except AttributeError:
        _ = trad.gettext

    if not options.quiet:
        show_logo()
        
        if not options.plugin_path:
            plugpath=["default path"]
        else:
            plugpath=options.plugin_path

        print(_("found #%s extensions") % len(extensions), "/", _("found #%s tests at %s") % (len(plugins), ", ".join(plugpath)))

    if not plugins and not extensions:
        LOG.error(_("did not discover any plugins, or were filtered"))

    if not options.quiet:
        if options.live:
            print(_("mode: live"))
        else:
            print(_("mode: fs snapshot %s" % CITELLUS_ROOT))

    # Execute runplugin for each plugin found
    results = docitellus(live=options.live, path=CITELLUS_ROOT, plugins=plugins)

    # Process Citellus extensions
    extensions = exts.initExtensions()

    for i in extensions:
        name = i.__name__.split(".")[-1]
        result = i.run(options)

    sys.exit(0)

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

        if options.only_failed and rc in [RC_OKAY, RC_SKIPPED]:
            continue

        if not options.blame:
            print("# %s: %s" % (result['plugin'], text))
        else:
            print("# %s (%s): %s" % (result['plugin'], result['time'], text))

        show_err = (
            (rc in [RC_FAILED]) or
            (rc not in [RC_OKAY, RC_FAILED, RC_SKIPPED]) or
            (rc in [RC_SKIPPED] and options.verbose > 0) or
            (options.verbose > 1)
        )

        show_out = (
            options.verbose > 1
        )

        if show_out and out.strip():
            print(indent(out, 4))

        if show_err and err.strip():
            print(indent(err, 4))

    if options.blame:
        print("# Total execution time: %s seconds" % (time.clock() - start_time))


if __name__ == "__main__":
    main()
