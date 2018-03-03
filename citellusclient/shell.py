#!/usr/bin/env python
# encoding: utf-8
#
# Description: Runs set of scripts against system or snapshot to
#              detect common pitfalls in configuration/status
#
# Copyright (C) 2017-2018 Robin Černín (rcernin@redhat.com)
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
from itertools import groupby
from multiprocessing import Pool, cpu_count
sys.path.append(os.path.abspath(os.path.dirname(__file__) + '/' + '../'))

LOG = logging.getLogger('citellus')

# Where are we?
global citellusdir
global localedir
global ExtensionFolder
global allplugins
global HooksFolder

citellusdir = os.path.abspath(os.path.dirname(__file__))
localedir = os.path.join(citellusdir, 'locale')
ExtensionFolder = os.path.join(citellusdir, "extensions")
HooksFolder = os.path.join(citellusdir, "hooks")
allplugins = []

global extensions
extensions = []
global exttriggers
exttriggers = {}
global hooks
hooks = []

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


def initExtensions(extensions=getExtensions()):
    """
    Initializes Extensions
    :return: list of Extension modules initialized
    """

    exts = []
    exttriggers = {}
    for i in extensions:
        newplug = loadExtension(i)
        exts.append(newplug)
        triggers = []
        for each in newplug.init():
            triggers.append(each)
        exttriggers[i["name"]] = triggers
    return exts, exttriggers


def getHooks(options=None):
    """
    Gets list of Hooks in the Hooks folder
    :return: list of Plugins available
    """

    if not options:
        hfilter = []
    else:
        hfilter = options.hfilter

    possibleHooks = findplugins(folders=[HooksFolder], executables=False, exclude=['__init__.py', 'pyc'], include=hfilter, fileextension='.py')

    # Sort hook names so that we can user XX_hook
    sortedhooks = []
    for i in possibleHooks:
        sortedhooks.append(i['plugin'])

    sortedhooks = sorted(set(sortedhooks))

    Hooks = []
    for i in sortedhooks:
        module = os.path.splitext(os.path.basename(i))[0]
        modpath = os.path.dirname(i)
        try:
            info = imp.find_module(module, [modpath])
        except:
            info = False
        if i and info:
            Hooks.append({"name": module, "info": info})

    return Hooks


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


def findallplugins():
    """
    Finds all plugins that citellus recognized
    :return: array of plugins found (dictionaries)
    """
    global extensions
    if not extensions:
        extensions, exttriggers = initExtensions()

    plugins = []
    for extension in extensions:
        plugins.extend(extension.listplugins())

    # Flatten plugins
    newplugins = []
    for extension in plugins:
        for plugin in extension:
            newplugins.append(plugin)

    return newplugins


def generate_file_hash(filename, blocksize=2**20):
    """
    Obtains a file hash for provided filename
    :param filename: file to open and hash
    :param blocksize: block size for chunks read
    :return: hash
    """
    hash = hashlib.md5()
    # Open File
    with open(filename, "rb") as f:
        while True:
            buffer = f.read(blocksize)
            if not buffer:
                break
            hash.update(buffer)
    return hash.hexdigest()


def findplugins(folders=None, include=None, exclude=None, executables=True, fileextension=False, extension='core', prio=0):
    """
    Finds plugins in path and returns array of them
    :param prio: define minimum priority of returned plugins
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
        subcategory = os.path.split(plugin)[0].replace(os.path.join(citellusdir, 'plugins', extension), '')
        category = os.path.normpath(subcategory).split(os.sep)[1] or ''

        # Remove leading "/" (os.sep for safety)
        if subcategory[0] == os.sep:
            subcategory = subcategory[1:]

        if category == subcategory:
            subcategory = ''

        dictionary = {'plugin': plugin,
                      'backend': extension,
                      'id': calcid(string=plugin),
                      'category': category,
                      'subcategory': subcategory,
                      'hash': generate_file_hash(filename=plugin),
                      'name': os.path.splitext(os.path.basename(plugin))[0]}
        dictionary.update(get_metadata(plugin=dictionary))

        if dictionary['priority'] >= prio:
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
                          'out': "%s" % out,
                          'err': "%s" % err},
               'time': time.time() - start_time}
    plugin.update(updates)
    return plugin


def calcid(string, replace=citellusdir):
    """
    Returns ID for defined string
    :param string: String to calculate md5 on
    :param replace: String to replace previous to calculation
    :return: md5sum of string
    """
    return hashlib.md5(string.replace(replace, '').encode('UTF-8')).hexdigest()


def getids(plugins=None, include=None, exclude=None):
    """
    Gets ID's for specified include/excluded plugins
    :param plugins: all plugins available
    :param include: keywords to include
    :param exclude: keywords to exclude
    :return: array of md5 hashes
    """
    if not plugins:
        plugins = findallplugins()

    allplugins = plugins
    newplugins = []

    for plugin in plugins:
        newplugins.append(plugin['plugin'])

    # Process plugins in include / exclude
    plugins = newplugins

    if include:
        plugins = [plugin for plugin in plugins
                   for filters in include
                   if filters in plugin]

    if exclude:
        plugins = [plugin for plugin in plugins
                   if not any(filters in plugin for filters in exclude)]

    # Get full plugins details

    ids = []
    for plugin in allplugins:
        if plugin['plugin'] in plugins:
            ids.append(plugin['id'])
    return ids


def execonshell(filename):
    """
    Executes command on shell
    :param filename: command to run or script name
    :return: returncode, out, err
    """
    try:
        p = subprocess.Popen(filename.split(" "), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        out, err = p.communicate(str.encode('utf8'))
        returncode = p.returncode
    except:
        returncode = 3
        out = ""
        err = traceback.format_exc()

    out = out.decode('utf-8').strip()
    err = err.decode('utf-8').strip()

    return returncode, out, err


def docitellus(live=False, path=False, plugins=False, lang='en_US', forcerun=False, savepath=False, include=None, exclude=None, okay=RC_OKAY, skipped=RC_SKIPPED, failed=RC_FAILED, web=False):
    """
    Runs citellus scripts on specified root folder
    :param web: Copy html to folder
    :param failed: RC for FAILED
    :param skipped: RC for SKIPPED
    :param okay: RC for OKAY
    :param exclude: keywords to exclude in plugins
    :param include: keywords to include in plugins
    :param savepath: Path to store resulting output
    :param forcerun: Forces execution instead of reading saved file
    :param lang: language to use on shell
    :param path: Path to analyze
    :param live:  Test is to be executed live or on snapshot/sosreport
    :param plugins:  plugins to execute against the system
    :return: Dict of plugins and results
    """

    start_time = time.time()

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
    os.environ['RC_OKAY'] = "%s" % okay
    os.environ['RC_FAILED'] = "%s" % failed
    os.environ['RC_SKIPPED'] = "%s" % skipped
    os.environ['TEXTDOMAIN'] = 'citellus'
    os.environ['TEXTDOMAINDIR'] = "%s/locale" % citellusdir

    # Set pool for same processes as CPU cores
    p = Pool(cpu_count())

    # We've save path, use it
    if savepath:
        LOG.debug("Storing output on %s" % savepath)
        filename = savepath
    elif path:
        # We don't have it, force to be sosreport folder
        filename = os.path.join(path, 'citellus.json')
        LOG.debug("Storing output on file %s" % filename)
    else:
        # For example for 'Live' environment where no path is defined
        filename = False

    missingplugins = []

    if live or forcerun:
        results = {}
    else:
        # If we can load, fill variable, else, just blank it
        LOG.debug("Reading Existing citellus analysis from disk for %s" % path)
        try:
            results = json.load(open(filename, 'r'))['results']
        except:
            results = {}

    # At this point we've 'results' with either empty dict (live, forcerun) or loaded if existing and valid

    # We do need to check that we've the results for all the plugins we know, if not, rerun.

    # Check all sosreports for data for all plugins
    allids = getids(plugins=plugins)

    # Now check in results for id's no longer existing for removal:
    delete = []
    for key in iter(results.keys()):
        if key not in allids:
            # Plugin ID no longer appears in found plugins.
            delete.append(key)

    LOG.debug("Removing old plugins from results: %s" % delete)

    for plugid in allids:
        if plugid not in results:
            missingplugins.append(plugid)

    LOG.debug("Adding new plugin id's missing to be executed: %s" % missingplugins)

    for key in delete:
        del results[key]

    # Prefill hashes of known plugins for checking same id's with changed hash
    hashes = []
    for plug in plugins:
        hashes.append(plug['hash'])

    # Check for changed plugins on disk vs stored
    for plugin in results:
        # We check all plugins in results
        try:
            hash = results[plugin]['hash']
        except:
            hash = False

        if hash not in hashes:
            # We now check all the available plugins for hashes
            # Plugin hash is not matched in results, rerun plugin as it has changed
            missingplugins.append(plugin)
            LOG.debug("Smart: rerunning plugin with modified hash on disk: %s" % results[plugin]['plugin'])

    # If some plugin is missing, rerun smart
    if len(missingplugins) != 0 or len(delete) != 0:
        missingplugins = sorted(set(missingplugins))
        LOG.debug("Running smartrun for plugins added %s" % missingplugins)
        LOG.debug("Running smartrun for plugins deleted %s" % delete)

    # We need to filter plugins only for the new id's what we were missing
    LOG.debug("Smart: We need to run some plugins that were missing")

    # We clear list of plugins to run to just grab the missing data
    pluginstorun = []
    for plugin in plugins:
        if plugin['id'] in missingplugins:
            pluginstorun.append(plugin)

    execution = p.map(runplugin, pluginstorun)

    for plugin in execution:
        results[plugin['id']] = dict(plugin)

    for hook in initExtensions(extensions=getHooks())[0]:
        LOG.debug("Running hook: %s" % hook.__name__.split('.')[-1])
        newresults = hook.run(data=results)
        if newresults:
            results = dict(newresults)

    # Write results if possible
    if filename:
        try:
            # Write results to disk
            branding = _("                                                  ")
            write_results(results, filename, path=path, time=time.time() - start_time, branding=branding, web=web)
        except:
            # Couldn't write
            LOG.debug("Couldn't write to file %s" % filename)

    # We've filters defined, so filter data
    if include or exclude:
        if include:
            oldresults = dict(results)
            results = {}
            for result in oldresults:
                add = False
                # Iterate for all known plugins on actual execution vs stored ones (or executed)
                for filters in include:
                    if filters in oldresults[result]['plugin']:
                        # We have a match with the plugin defined and the ones we expect, so append results
                        add = True
                if add:
                    results[result] = dict(oldresults[result])

        if exclude:
            oldresults = dict(results)
            results = {}
            for result in oldresults:
                add = True
                # Iterate for all known plugins on actual execution vs stored ones (or executed)
                for filters in exclude:
                    if filters in oldresults[result]['plugin']:
                        add = False
                if add:
                    results[result] = dict(oldresults[result])

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
    p.add_argument("--list-categories",
                   action="store_true",
                   help=_("With list-plugins, also print a list and count of discovered plugin categories"))
    p.add_argument("--description",
                   action="store_true",
                   help=_("With list-plugins, also outputs plugin description"))
    p.add_argument("--list-hooks",
                   action="store_true",
                   help=_("Print a list of discovered hooks and exit"))
    p.add_argument("--output", "-o",
                   metavar="FILENAME",
                   help=_("Write results to JSON file FILENAME"))
    p.add_argument("--web",
                   action="store_true",
                   help=_("Write results to JSON file citellus.json and copy html interface in path defined in --output"))
    p.add_argument("--run", "-r",
                   action='store_true',
                   help=_("Force run of citellus instead of reading existing 'citellus.json'"))

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
    g.add_argument("-p", "--prio",
                   metavar='[0-1000]',
                   type=int,
                   choices=range(0, 1001),
                   help=_("Only include plugins are equal or above specified prio"),
                   default=0)
    g.add_argument("-hf", "--hfilter",
                   metavar='SUBSTRING',
                   help=_("Only include hooks that contain substring"),
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
    for filename in [os.path.join(citellusdir, 'citellus.conf'), os.path.expanduser("~/.citellus.conf")]:
        if os.path.exists(filename):
            config = json.load(open(filename, 'r'))

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


def write_results(results, filename, live=False, path=None, time=0, source='citellus', branding='', web=False):
    """
    Writes result
    :param web: copy html viewer
    :param branding: branding string for metadata
    :param source: source of information for metadata
    :param time: date of report
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
            'source': source,
            'time': time,
            'branding': branding
        },
        'results': results,
    }

    if path:
        data['metadata']['path'] = path

    if os.access(os.path.join(os.path.dirname(filename), 'citellus.html'), os.W_OK):
        LOG.debug("We can copy html again as we've W_OK")
        web = True

    if web:
        basefolder = os.path.dirname(filename)

        if basefolder == '':
            basefolder = './'
        src = os.path.join(citellusdir, 'citellus.html')
        if os.path.isfile(src):
            shutil.copyfile(src, os.path.join(basefolder, os.path.basename(src)))

    try:
        with open(filename, 'w') as fd:
            json.dump(data, fd, indent=2)
    except:
        LOG.debug("Failed to write to file %s" % filename)


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

    global _, CITELLUS_ROOT

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
        elif not options.list_plugins and not options.list_extensions and not options.list_hooks:
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

    hooks, hooktriggers = initExtensions(extensions=getHooks(options))

    # List Hooks and exit
    if options.list_hooks:
        for hook in hooks:
            print(hook.__name__.split(".")[-1])
            if options.description:
                desc = hook.help()
                if desc:
                    print(indent(text=desc, amount=4))
        return

    # Prefill plugin list as we'll be still using it for execution
    plugins = []
    for extension in extensions:
        plugins.extend(extension.listplugins(options))

    global allplugins
    allplugins = plugins

    # Print plugin list and description if requested
    categories = []
    grosscategories = []

    if options.list_plugins:
        for extension in plugins:
            for plugin in extension:
                pretty = {'plugin': plugin['plugin'], 'backend': plugin['backend'], 'id': plugin['id'], 'name': plugin['name']}
                if options.description:
                    pretty.update({'description': plugin['description']})
                if options.list_categories:
                    pretty.update({'category': plugin['category']})
                    pretty.update({'subcategory': plugin['subcategory']})
                if options.loglevel == 'DEBUG' or options.verbose:
                    pretty.update({'id': plugin['id']})
                print(pretty)

        if options.list_categories:
            for extension in plugins:
                for plugin in extension:
                    # Split category out of plugin path skipping the first item (for backend, etc)
                    category = os.path.split(plugin['plugin'])[0].replace(os.path.join(citellusdir, 'plugins', plugin['backend']), '')

                    # We do create two lists, one for the individual items for detailed count and one for the parent folder for totals
                    categories.append(category)
                    grosscategories.append(plugin['category'])

            # Get counters and start the information processing
            detail = sorted([(key, len(list(v))) for (key, v) in groupby(sorted(categories))])
            count = sorted([(key, len(list(v))) for (key, v) in groupby(sorted(grosscategories))])
            total = 0

            print("-------\n")

            for each in count:
                key, elem = each
                detailed = []
                for subitem in detail:
                    startpath = os.path.join(os.sep, key)
                    subkey, subval = subitem
                    # List the items within that 'root' category and remove common path
                    if subkey.startswith(startpath):
                        subcount = "%s" % subval
                        newdetail = subkey.replace(startpath, '')

                        # Remove leading "/" (os.sep for safety)
                        if newdetail != '' and newdetail[0] == os.sep:
                            newdetail = newdetail[1:]

                        # Skip empty strings and instead just show empty array
                        if newdetail != '':
                            detailed.append(newdetail + ": " + subcount)
                print(key, ":", elem, detailed)
                total = total + elem

            print("-------\ntotal", ":", total)
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
    forcerun = options.run

    results = docitellus(live=options.live, path=CITELLUS_ROOT, plugins=plugins, lang=options.lang, forcerun=forcerun, savepath=options.output, include=options.include, exclude=options.exclude, web=options.web)

    # Print results based on the sorted order based on returned results from
    # parallel execution

    for result in results:
        out = results[result]['result']['out']
        err = results[result]['result']['err']
        rc = results[result]['result']['rc']
        text = formattext(rc)

        if options.only_failed and rc in [RC_OKAY, RC_SKIPPED]:
            continue

        if not options.blame:
            print("# %s: %s" % (results[result]['plugin'], text))
        else:
            print("# %s (%s): %s" % (results[result]['plugin'], results[result]['time'], text))

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

    totaltime = time.time() - start_time

    if options.blame:
        print("# Total execution time: %s seconds" % totaltime)


if __name__ == "__main__":
    main()
