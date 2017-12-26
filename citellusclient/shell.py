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
import hashlib
import imp
import json
import logging
import os
import re
import shutil
import subprocess
import sys
import time
import traceback
from multiprocessing import Pool, cpu_count

LOG = logging.getLogger('citellus')

# Where are we?
global citellusdir
global localedir
global ExtensionFolder
citellusdir = os.path.abspath(os.path.dirname(__file__))
localedir = os.path.join(citellusdir, 'locale')
ExtensionFolder = os.path.join(citellusdir, "extensions")

global extensions
extensions = []
global exttriggers
exttriggers = {}

global CITELLUS_LIVE
CITELLUS_LIVE = 0


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


def getExtensions():
    """
    Gets list of Extensions in the Extensions folder
    :return: list of Extensions available
    """

    Extensions = []
    possibleExtensions = os.listdir(ExtensionFolder)
    for i in possibleExtensions:
        if i != "__init__.py" and os.path.splitext(i)[1] == ".py":
            i = os.path.splitext(i)[0]
        try:
            info = imp.find_module(i, [ExtensionFolder])
        except:
            info = False
        if i and info:
            Extensions.append({"name": i, "info": info})

    return Extensions


def loadExtension(Extension):
    """
    Loads selected Extension
    :param Extension: Extension to load
    :return: loader for Extension
    """
    return imp.load_module(Extension["name"], *Extension["info"])


def initExtensions():
    """
    Initializes Extensions
    :return: list of Extension modules initialized
    """

    exts = []
    exttriggers = {}
    for i in getExtensions():
        newplug = loadExtension(i)
        exts.append(newplug)
        triggers = []
        for each in newplug.init():
            triggers.append(each)
        exttriggers[i["name"]] = triggers
    return exts, exttriggers


def which(binary):
    """
    Locates where a binary is located within path
    :param binary: Binary to locate/executable
    :return: path or None if not found
    """

    def is_executable(filename):
        """
        Returns True if filename is executable, False otherwise
        :param filename: File to check
        :return: True or False if executable or not
        """
        return os.path.isfile(filename) and os.access(filename, os.X_OK)

    path, filename = os.path.split(binary)
    if path:
        if is_executable(binary):
            return binary
    else:
        for path in os.environ["PATH"].split(os.pathsep):
            executable = os.path.join(path, binary)
            if is_executable(executable):
                return executable

    return None


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


def findplugins(folders, include=None, exclude=None, executables=True, fileextension=False, extension='core'):
    """
    Finds plugins in path and returns array of them
    :param executables: Enable to find only executable files
    :param fileextension: Extension to match for plugins found
    :param extension: Extension that will handle this plugin
    :param exclude: exclude string in filter path
    :param include: include string in filter path
    :param folders: Folders to use as source for plugin search
    :return: list of plugins found
    """

    if not folders:
        folders = [os.path.join(citellusdir, 'plugins')]

    LOG.debug('starting plugin search in: %s', folders)

    # Workaround if calling externally
    global extensions
    if not extensions:
        extensions, exttriggers = initExtensions()

    plugins = []
    for folder in folders:
        for root, dirnames, filenames in os.walk(folder):
            LOG.debug('looking for plugins in: %s', root)
            for filename in filenames:
                filepath = os.path.join(root, filename)
                LOG.debug('considering: %s', filepath)
                passesextension = False
                if fileextension:
                    if os.path.splitext(filepath)[1] == fileextension:
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
                   for filters in include
                   if filters in plugin]

    if exclude:
        plugins = [plugin for plugin in plugins
                   if not any(filters in plugin for filters in exclude)]

    LOG.debug(msg=_('Found plugins: %s') % plugins)

    # this unique-ifies the list of plugins (and ensures consistent
    # ordering).

    plugins = sorted(set(plugins))

    # Build dictionary of plugins and it's metadata
    metaplugins = []
    for plugin in plugins:
        dictionary = {'plugin': plugin, 'backend': extension, 'id': hashlib.md5(plugin.encode('UTF-8')).hexdigest()}
        dictionary.update(get_metadata(plugin=dictionary))
        metaplugins.append(dictionary)

    return metaplugins


def runplugin(plugin):
    """
    Runs provided plugin and outputs message
    :param plugin:  plugin to execute
    :return: result, out, err
    """

    LOG.debug(msg=_('Running plugin: %s') % plugin)
    start_time = time.time()
    os.environ['PLUGIN_BASEDIR'] = "%s" % os.path.abspath(os.path.dirname(plugin['plugin']))

    # By default prepare 'error' in case of failed mapping from plugin to extension
    returncode = 3
    out = ''
    err = 'Error finding extension to run plugin'

    # Workaround if calling externally
    global extensions
    if not extensions:
        extensions, exttriggers = initExtensions()

    found = 0
    for extension in extensions:
        name = extension.__name__.split(".")[-1]
        if plugin['backend'] == name:
            returncode, out, err = extension.run(plugin=plugin)
            found = 1
    if found == 0:
        LOG.debug(err + ":" + plugin)

    updates = {'result': {'rc': returncode,
                          'out': out.decode('ascii', 'ignore'),
                          'err': err.decode('ascii', 'ignore')},
               'time': time.time() - start_time}
    plugin.update(updates)
    return plugin


def execonshell(filename):
    """
    Executes command on shell
    :param filename: command to run or script name
    :return: returncode, out, err
    """
    try:
        p = subprocess.Popen(filename.split(" "), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        out, err = p.communicate()
        returncode = p.returncode
    except:
        returncode = 3
        out = ""
        err = traceback.format_exc()
    return returncode, out, err


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
    global CITELLUS_LIVE
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
    p.add_argument("--list-extensions",
                   action="store_true",
                   help=_("Print a list of discovered extensions and exit"))
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

    p.add_argument('sosreport', nargs='?')

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
    """
    Converts dictionary into argparse options
    :param config: dictionary
    :param path: extra path
    :return: argparse options object
    """
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
        valid.append(path)
    return parse_args(parse=valid)


def read_config():
    """
    Reads configuration options
    :return: with options stored on file
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
    :param path: Keep or purge path from returned options
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
    :param path: print or not path for sosreports
    :param options: options used
    """
    differences = diff_config(options=options, path=path)
    # Output config to stdout
    return json.dumps(differences)


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


def regexpfile(filename=False, regexp=False):
    """
    Checks for string in file
    :param filename: filename to regexp for matches
    :param regexp: String to check
    :return: found match or False
    """

    if not regexp:
        return False

    with open(filename, 'r') as f:
        for line in f:
            if re.match(regexp, line):
                # Return earlier if match found
                return line

    return ''


def get_metadata(plugin=False):
    """
    Gets metadata for provided plugin
    :param plugin:  plugin
    :return: metadata text
    """

    metadata = {}
    for extension in extensions:
        name = extension.__name__.split(".")[-1]
        if plugin['backend'] == name:
            return extension.get_metadata(plugin)

    return metadata


def main():
    """
    Main function for the program
    :return: none
    """

    start_time = time.time()

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
        if options.sosreport:
            # Live not specified, so we will use file snapshot
            CITELLUS_ROOT = options.sosreport
        elif not options.list_plugins and not options.list_extensions:
            LOG.error(_("When not running in Live mode, snapshot path is required"))
            sys.exit(1)
    else:
        CITELLUS_ROOT = ""

    # Process Citellus extensions
    global extensions
    global triggers

    extensions, exttriggers = initExtensions()

    # List extensions and exit
    if options.list_extensions:
        for extension in extensions:
            print(extension.__name__.split(".")[-1])
            if options.description:
                desc = extension.help()
                if desc:
                    print(indent(text=desc, amount=4))
        return

    # Prefill plugin list as we'll be still using it for execution
    plugins = []
    for extension in extensions:
        plugins.extend(extension.listplugins(options))

    # Print plugin list and description if requested
    if options.list_plugins:
        for extension in plugins:
            for plugin in extension:
                pretty = {'plugin': plugin['plugin'], 'backend': plugin['backend']}

                if options.description:
                    pretty.update({'description': plugin['description']})
                print(pretty)
        return

    # Reinstall language in case it has changed
    trad = gettext.translation('citellus', localedir, fallback=True, languages=[options.lang])

    try:
        _ = trad.ugettext
    except AttributeError:
        _ = trad.gettext

    if not options.quiet:
        show_logo()
        totalplugs = 0
        for extension in plugins:
            totalplugs += len(extension)
        print(_("found #%s extensions with #%s plugins") % (len(extensions), totalplugs))

    if not extensions:
        LOG.error(_("did not discover any plugins, or were filtered"))

    if not options.quiet:
        if options.live:
            print(_("mode: live"))
        else:
            print(_("mode: fs snapshot %s" % CITELLUS_ROOT))

    # Process Citellus extensions

    # By default
    newplugins = []
    for each in plugins:
        newplugins.extend(each)

    plugins = newplugins
    results = docitellus(live=options.live, path=CITELLUS_ROOT, plugins=plugins, lang=options.lang)

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
            src = os.path.join(citellusdir, '../tools/www/citellus.html')
            if os.path.isfile(src):
                shutil.copyfile(src, os.path.join(basefolder, os.path.basename(src)))

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
        print("# Total execution time: %s seconds" % (time.time() - start_time))


if __name__ == "__main__":
    main()
