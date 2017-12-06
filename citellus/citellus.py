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
import shutil

try:
    import exts
except ImportError:
    from citellus import exts

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
    """
    Returns color for text
    :param text: test to colorize
    :param color: color to use
    :param stream: where to output
    :param force: force
    :return: string for setting/resetting format
    """
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


def findplugins(folders, include=None, exclude=None, executables=True, extension=False):
    """
    Finds plugins in path and returns array of them
    :param exclude: exclude string in filter path
    :param include: include string in filter path
    :param folders: Folders to use as source for plugin search
    :return: list of plugins found
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
                passesextension = False
                if extension:
                    if os.path.splitext(filepath)[1] == extension:
                        passesextension = True
                else:
                    passesextension = True

                if passesextension is True:
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
        p = subprocess.Popen(plugin.split(" "), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
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
    :param lang: language to use on shell
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


def parse_args(default=False, parse=False):
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
    p.add_argument("--web",
                   action="store_true",
                   help=_("Write results to JSON file citellus.json and copy html interface in path defined in --output"))

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
    s = p.add_argument_group('Config options')
    s.add_argument("--dump-config", help=_("Dump config to console to be saved into file"), default=False, action="store_true")
    s.add_argument("--no-config", default=False, help=_("Do not read configuration from file %s or ~/.citellus.conf" % os.path.join(citellusdir, "citellus.conf")), action="store_true")

    p.add_argument('sosreport', nargs='*')

    if not default and not parse:
        return p.parse_args()
    else:
        # Return default settings or custom ones
        if default:
            # Return defaults
            return p.parse_args([])
        if parse:
            # Parse defined settings
            return p.parse_args(parse)


def array_to_config(config, path=False):
    valid = []
    if isinstance(config, dict):
        for key in config:
            values = config[key]
            if isinstance(values, str):
                values = values.encode('ascii', 'ignore')
            if isinstance(values, list):
                for value in values:
                    if key == 'sosreport':
                        valid.append("%s" % key.encode('ascii', 'ignore'))
                    else:
                        valid.append("--%s" % key.encode('ascii', 'ignore'))
                    if value is not True and value != "True":
                        valid.append(value)
            else:
                if key == 'verbose':
                    valid.append("--%s" % key)
                else:
                    valid.append("--%s" % key.encode('ascii', 'ignore'))
                    if values is not True and values != "True":
                        valid.append(values)

    # We do add paths at the end without any parameter
    if path:
        for each in path:
            valid.append(each)
    return parse_args(parse=valid)


def read_config():
    """
    Reads configuration options
    :param options: options passed
    :return: json with options stored on file
    """
    # Order for options will be:
    #   - First program defaults
    #   - Overwritten with citellus folder options
    #   - Overwritten with citellus user options
    #   - Overwritten with citellus CLI options

    # check for valid config files

    config = {}
    for file in [os.path.join(citellusdir, 'citellus.conf'), os.path.expanduser("~/.citellus.conf")]:
        if os.path.exists(file):
            config = json.load(open(file, 'r'))

    return config


def diff_config(options, defaults=parse_args(default=True), path=False):
    """
    Diffs between default configuration and provided one
    :param options: options provided
    :param defaults: default configuration options
    :return: dict with different values to defaults
    """
    config = {}
    for key in vars(options):
        keydef = vars(defaults)[key]
        keyset = vars(options)[key]
        if keyset != keydef and key != 'dump_config' and key != 'no_config' and key != 'sosreport':
            # argparse replaces "-" by "_" on keys so we revert
            key = key.replace("_", "-")
            config[key] = keyset
        if path and key == 'sosreport':
            # If we tell to return path, do put in the list of config options
            config[key] = keyset

    return config


def dump_config(options, path=False):
    """
    Dumps config options that differ from defaults
    :param options: options used
    """
    differences = diff_config(options=options, path=path)
    # Output config to stdout
    return(json.dumps(differences))


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


def regexpfile(file=False, regexp=False):
    """
    Checks for string in file
    :param file: file to check
    :param regexp: String to check
    :return: found match or False
    """

    if not regexp:
        return False

    with open(file, 'r') as f:
        for line in f:
            if re.match(regexp, line):
                # Return earlier if match found
                return line

    return False


def get_description(plugin=False):
    """
    Gets description for provided plugin
    :param plugin:  plugin
    :return: Description text
    """
    return regexpfile(file=plugin, regexp='\A# description:')


def main():
    """
    Main function for the program
    :return: none
    """

    start_time = time.clock()

    # Store CLI options for reporting later
    clioptions = parse_args()
    options = clioptions

    # Configure logging
    logging.basicConfig(level=options.loglevel)

    if options.dump_config:
        options.no_config = True
        print(dump_config(options))
        sys.exit(0)

    if not options.no_config:
        # Should be default always to read config
        savedconfig = read_config()

        # Check that saved config is not empty
        if savedconfig != {}:
            # Saved config is not empty, merge saved with CLI passed ones
            cliconfig = json.loads(dump_config(options=options, path=True))
            # Generate empty config and update with the saved and overwrite with CLI provided one
            newconfig = {}
            newconfig.update(savedconfig)
            newconfig.update(cliconfig)

            # remove plugin path from dictionary and have array_to_config to append it
            path = newconfig['sosreport']
            del newconfig['sosreport']
            # Generate to options like if they were all parsed via CLI
            options = array_to_config(config=newconfig, path=path)
    else:
        savedconfig = 'ignored'

    global _

    # Configure ENV language before anything else
    os.environ['LANG'] = "%s" % options.lang

    # Reconfigure logging
    logging.basicConfig(level=options.loglevel)

    LOG.debug("# Using saved options: %s" % savedconfig)
    LOG.debug("# CLI options: %s" % diff_config(options=clioptions, path=True))
    LOG.debug("# Effective options for this run: %s" % diff_config(options=options, path=True))

    if not options.live:
        if len(options.sosreport) > 0:
            # Live not specified, so we will use file snapshot as first arg and remaining cli arguments as plugins
            CITELLUS_ROOT = options.sosreport.pop(0)
        elif not options.list_plugins:
            LOG.error(_("When not running in Live mode, snapshot path is required"))
            sys.exit(1)
    else:
        CITELLUS_ROOT = ""

    LOG.info('using default plugin path')

    # Process Citellus extensions
    global extensions
    extensions = exts.initExtensions()

    if options.list_plugins:
        for each in extensions:
            print("#PYEXT: %s" % each.__name__.split(".")[-1])
            if options.description:
                desc = each.help()
                if desc:
                    print(desc)
            # print the list of each extension additional files (i.e. playbooks for ansible, etc)
            for extlist in each.list(options):
                print(extlist)

        return

    # Reinstall language in case it has changed
    trad = gettext.translation('citellus', localedir, fallback=True, languages=[options.lang])

    try:
        _ = trad.ugettext
    except AttributeError:
        _ = trad.gettext

    if not options.quiet:
        show_logo()

        plugpath = ["default path"]
        
        print(_("found #%s extensions") % len(extensions))

    if not extensions:
        LOG.error(_("did not discover any plugins, or were filtered"))

    if not options.quiet:
        if options.live:
            print(_("mode: live"))
        else:
            print(_("mode: fs snapshot %s" % CITELLUS_ROOT))

    # Process Citellus extensions
    extensions = exts.initExtensions()

    results = []

    for i in extensions:
        name = i.__name__.split(".")[-1]
        print("# Running extension %s" % name)
        result = i.run(options)

        # Add extension results to citellus results
        if result:
            results.extend(result)

    if options.output:
        if not options.web:
            write_results(results, options.output,
                          live=options.live,
                          path=CITELLUS_ROOT)
        else:
            basefolder = os.path.dirname(options.output)
            if basefolder == '':
                basefolder = './'
            newfile = os.path.join(basefolder, 'citellus.json')
            write_results(results, newfile,
                          live=options.live,
                          path=CITELLUS_ROOT)
            shutil.copy2(os.path.join(citellusdir, '../tools/www/citellus.html'), basefolder)

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
