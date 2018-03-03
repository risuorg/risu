#!/usr/bin/env python
# encoding: utf-8
#
# Description: Multiple Analysis Generic Unifier and Interpreter aka Magui
#              This program processes several snapshoot/sosreport files
#              and processes citellus output for combined issues via plugins
#              that search for specific plugin and data
#
# Copyright (C) 2017  Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)
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
import glob
import hashlib
import imp
import logging
import os.path
import pprint
import time
import sys
sys.path.append(os.path.abspath(os.path.dirname(__file__) + '/' + '../'))

from citellusclient import shell as citellus

LOG = logging.getLogger('magui')

# Where are we?
maguidir = os.path.abspath(os.path.dirname(__file__))
localedir = os.path.join(citellus.citellusdir, 'locale')

global PluginsFolder
PluginsFolder = os.path.join(maguidir, "plugins")

global plugins
plugins = []
global plugtriggers
plugtriggers = {}

trad = gettext.translation('citellus', localedir, fallback=True)

try:
    _ = trad.ugettext
except AttributeError:
    _ = trad.gettext


def show_logo():
    """
    Prints Magui Logo
    :return:
    """

    logo = "    _    ", \
           "  _( )_  Magui:", \
           " (_(ø)_) ", \
           "  /(_)   Multiple Analisis Generic Unifier and Interpreter", \
           " \|      ", \
           "  |/     ", \
           ""
    print("\n".join(logo))


def parse_args():
    """
    Parses arguments on commandline
    :return: parsed arguments
    """
    description = _('Processes several generic archives/sosreports scripts in a uniform way, to interpret status that depend on several systems data')

    # Option parsing
    p = argparse.ArgumentParser("magui.py [arguments]", description=description)
    p.add_argument('-d', "--loglevel",
                   help=_("Set log level"),
                   default="info",
                   type=lambda x: x.upper(),
                   choices=["INFO", "DEBUG", "WARNING", "ERROR", "CRITICAL"])
    p.add_argument("--list-plugins",
                   action="store_true",
                   help=_("Print a list of discovered Magui plugins and exit"))
    p.add_argument("--description",
                   action="store_true",
                   help=_("With list-plugins, also outputs plugin description"))
    p.add_argument('-m', "--mpath", dest="mpath",
                   help=_("Set path for Magui plugin location if not default"),
                   action='append')
    p.add_argument("--output", "-o",
                   metavar="FILENAME",
                   help=_("Write results to JSON file FILENAME"))
    p.add_argument("--run", "-r",
                   action='store_true',
                   help=_("Force run of citellus instead of reading existing 'citellus.json'"))
    p.add_argument("--hosts",
                   metavar="hosts",
                   help=_("Gather data via ansible from remote hosts to process."))

    g = p.add_argument_group('Filtering options')
    g.add_argument("-q", "--quiet",
                   help=_("Enable quiet mode"),
                   action='store_true')
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
    g.add_argument("-mf", "--mfilter", dest="mfilter",
                   help=_("Only include Magui plugins that contains in full path that substring"),
                   default=[],
                   action='append')
    g.add_argument("--lang",
                   action="store_true",
                   help=_("Define locale to use"),
                   default='en_US')

    p.add_argument('sosreports', nargs='*')

    return p.parse_args()


def commonpath(folders):
    """
    Checks the minimum common path in provided paths
    :param folders: path array for folder
    :return: string: common path
    """

    code = ""
    if folders:
        try:
            # Python 3.x
            code = os.path.commonpath(folders)
        except AttributeError:
            # Python 2.x
            code = os.path.commonprefix(folders).rsplit('/', 1)[0]

    return code


def getPlugins(options):
    """
    Gets list of Plugins in the plugins folder
    :return: list of Plugins available
    """

    Plugins = []
    possiblePlugins = citellus.findplugins(folders=[PluginsFolder], executables=False, exclude=['__init__.py', 'pyc'], include=options.mfilter, fileextension='.py')
    for i in possiblePlugins:
        module = os.path.splitext(os.path.basename(i['plugin']))[0]
        modpath = os.path.dirname(i['plugin'])
        try:
            info = imp.find_module(module, [modpath])
        except:
            info = False
        if i['plugin'] and info:
            Plugins.append({"name": module, "info": info})

    return Plugins


def loadPlugin(Plugin):
    """
    Loads selected Plugin
    :param Plugin: Plugin to load
    :return: loader for Plugin
    """
    return imp.load_module(Plugin["name"], *Plugin["info"])


def initPlugins(options):
    """
    Initializes Plugins
    :return: list of Plugin modules initialized
    """

    plugs = []
    plugtriggers = {}
    for i in getPlugins(options):
        newplug = loadPlugin(i)
        plugs.append(newplug)
        triggers = []
        for each in newplug.init():
            triggers.append(each)
        plugtriggers[i["name"]] = triggers
    return plugs, plugtriggers


def callcitellus(path=False, plugins=False, forcerun=False, include=None, exclude=None):
    """
    Do actual execution of citellus against data
    :param exclude: keywords to exclude
    :param include: keywords to include
    :param forcerun: Forces execution of citellus analysis (ignoring saved data in citellus.json)
    :param path: sosreport path
    :param plugins: plugins enabled as provided to citellus
    :return: dict with results
    """

    # Call citellus normally, if existing prior results those will be loaded or executed + saved
    results = citellus.docitellus(path=path, plugins=plugins, forcerun=forcerun, include=include, exclude=exclude)

    # Process plugin output from multiple plugins
    new_dict = {}
    for item in results:
        name = results[item]['id']
        new_dict[name] = dict(results[item])
    return new_dict


def domagui(sosreports, citellusplugins, options=False):
    """
    Do actual execution against sosreports
    :return: dict of result
    """

    # Check if we've been provided options
    if options:
        forcerun = options.run
        citinclude = options.include
        citexclude = options.exclude
        hosts = options.hosts
    else:
        forcerun = False
        citinclude = None
        citexclude = None
        hosts = False

    # Grab data from citellus for the sosreports provided
    result = {}

    for sosreport in sosreports:
        result[sosreport] = callcitellus(path=sosreport, plugins=citellusplugins, forcerun=forcerun, include=citinclude, exclude=citexclude)

    # Sanity check in case we do need to force run because of inconsistencies between saved data
    if not forcerun:
        # Prefill all plugins
        plugins = []
        for sosreport in sosreports:
            for plugin in result[sosreport]:
                plugins.append(plugin)

        plugins = sorted(set(plugins))

        rerun = False
        # Check all sosreports for data for all plugins
        for sosreport in sosreports:
            for plugin in plugins:
                try:
                    result[sosreport][plugin]['result']
                except:
                    rerun = True

            # If we were running against a folder with just json, cancel rerun as it will fail
            if rerun:
                try:
                    access = os.access(os.path.join(sosreport, 'version.txt'), os.R_OK)
                except:
                    access = False

                if not access:
                    # We're running against a folder that misses version.txt, so probably just folder with json, skip rerun
                    rerun = False

            # Forcing rerun but not if we've specified ansible hosts
            if rerun and not hosts:
                LOG.debug("Forcing rerun of citellus for %s because of missing %s" % (sosreport, plugin))
                # Sosreport contains non uniform data, rerun
                result[sosreport] = callcitellus(path=sosreport, plugins=citellusplugins, forcerun=True)

    # Precreate multidimensional array
    grouped = {}
    for sosreport in sosreports:
        plugins = []
        for plugin in result[sosreport]:
            plugins.append(plugin)
            grouped[plugin] = {}
            grouped[plugin]['sosreport'] = {}

    # Fill the data
    for sosreport in sosreports:
        for plugin in result[sosreport]:
            grouped[plugin]['sosreport'][sosreport] = result[sosreport][plugin]['result']
            for element in result[sosreport][plugin]:
                # Some of the elements are not useful as they are sosreport specific, so we do skip them completely
                # In this approach we don't need to update this code each time the plugin exports new metadata
                if element not in ['time', 'result']:
                    grouped[plugin][element] = result[sosreport][plugin][element]

    # We've now a matrix of grouped[plugin][sosreport] and then [text] [out] [err] [rc]
    return grouped


def maguiformat(data):
    """
    Formats the data from Magui for printing
    :param data: Result from domagui
    :return: dict with result for printing
    """
    toprint = {}

    plugins = []
    for plugin in data:
        plugins.append(plugin)

    # Calculate common path for later filtering for output print
    cp = commonpath(plugins)

    for plugin in data:
        pplug = 0
        for host in data[plugin]['sosreport']:
            if data[plugin]['sosreport'][host]['rc'] not in [citellus.RC_OKAY, citellus.RC_SKIPPED]:
                pplug = 1
        if pplug == 1:
            newplugin = plugin.replace(cp, '')
            toprint[newplugin] = {}

            # Fill metadata for plugin
            for key in data[plugin]:
                if key not in ['sosreport']:
                    toprint[newplugin][key] = data[plugin][key]

            toprint[newplugin]['sosreport'] = {}
            for host in data[plugin]:
                toprint[newplugin]['sosreport'][host] = {}
                toprint[newplugin]['sosreport'][host] = data[plugin][host]
    return toprint


def filterresults(data, triggers=[]):
    """
    Filters results for only the data that plugin will use
    :param data: full set of data
    :param triggers: set of triggers (plugin ID's) to match
    :return: filtered data of only those plugins
    """
    if '*' in triggers:
        # If plugin processes everything, return all data
        return data

    ourdata = {}
    for trigger in triggers:
        for elem in data:
            # We do use this approach in case of 'faked' id's like multi-Faraday bundles
            if trigger in data[elem]['id']:
                ourdata[data[elem]['id']] = dict(data[elem])
    return ourdata


def main():
    """
    Main code stub
    """

    start_time = time.time()

    options = parse_args()

    # Configure ENV language before anything else
    os.environ['LANG'] = "%s" % options.lang

    # Reinstall language in case it has changed
    trad = gettext.translation('citellus', localedir, fallback=True, languages=[options.lang])

    try:
        _ = trad.ugettext
    except AttributeError:
        _ = trad.gettext

    # Configure logging
    logging.basicConfig(level=options.loglevel)

    if not options.quiet:
        show_logo()

    # Each argument in sosreport is a sosreport

    magplugs, magtriggers = initPlugins(options)

    if options.list_plugins:
        for plugin in magplugs:
            print("-", plugin.__name__.split(".")[-1])
            if options.description:
                desc = plugin.help()
                if desc:
                    print(citellus.indent(text=desc, amount=4))
        return

    # Prefill enabled citellus plugins from args
    if not citellus.extensions:
        extensions, exttriggers = citellus.initExtensions()
    else:
        extensions = citellus.extensions

    # Grab the data
    sosreports = options.sosreports

    if options.hosts:
        ansible = citellus.which("ansible-playbook")
        if not ansible:
            LOG.err(_("No ansible-playbook support found, skipping"))
        else:
            LOG.info("Grabbing data from remote hosts with Ansible")
            # Grab data from ansible hosts

            # Disable Ansible retry files creation:
            os.environ['ANSIBLE_RETRY_FILES_ENABLED'] = "0"

            if options.loglevel == 'DEBUG':
                # Keep ansible remote files for debug
                os.environ['ANSIBLE_KEEP_REMOTE_FILES'] = "1"

            command = "%s -i %s %s" % (ansible, options.hosts, os.path.join(maguidir, 'remote.yml'))

            LOG.debug("Running: %s " % command)
            citellus.execonshell(filename=command)

            # Now check the hosts we got logs from:
            hosts = citellus.findplugins(folders=glob.glob('/tmp/citellus/hostrun/*'), executables=False, fileextension='.json')
            for host in hosts:
                sosreports.append(os.path.dirname(host['plugin']))

    # Get all data from hosts for all plugins, etc
    if options.output:

        citellusplugins = []
        # Prefill with all available plugins and the ones we want to filter for
        for extension in extensions:
            citellusplugins.extend(extension.listplugins())

        global allplugins
        allplugins = citellusplugins

        # By default, flatten plugin list for all extensions
        newplugins = []
        for each in citellusplugins:
            newplugins.extend(each)

        citellusplugins = newplugins

        # Run with all plugins so that we get all data back
        grouped = domagui(sosreports=sosreports, citellusplugins=citellusplugins)

        # Run Magui plugins
        result = []
        for plugin in magplugs:
            start_time = time.time()
            # Get output from plugin
            data = filterresults(data=grouped, triggers=magtriggers[plugin.__name__.split(".")[-1]])
            returncode, out, err = plugin.run(data=data, quiet=options.quiet)
            updates = {'rc': returncode,
                       'out': out,
                       'err': err}

            subcategory = os.path.split(plugin.__file__)[0].replace(os.path.join(maguidir, 'plugins', ''), '')

            if subcategory:
                if len(os.path.normpath(subcategory).split(os.sep)) > 1:
                    category = os.path.normpath(subcategory).split(os.sep)[0]
                else:
                    category = subcategory
                    subcategory = ""
            else:
                category = ""

            mydata = {'plugin': plugin.__name__.split(".")[-1],
                      'name': "magui: %s" % os.path.basename(plugin.__name__.split(".")[-1]),
                      'id': hashlib.md5(plugin.__file__.replace(maguidir, '').encode('UTF-8')).hexdigest(),
                      'description': plugin.help(),
                      'long_name': plugin.help(),
                      'result': updates,
                      'time': time.time() - start_time,
                      'category': category,
                      'subcategory': subcategory}

            result.append(mydata)
        branding = _("                                                  ")
        citellus.write_results(results=result, filename=options.output, source='magui', path=sosreports, time=time.time() - start_time, branding=branding, web=True)

    # Here preprocess output to use filtering, etc
    # "result" does contain all data for both all citellus plugins and all magui plugins, need to filter for output on CLI only

    # As we don't have a proper place to store output and we're running the full set of tests only when output is going
    # to be stored (and then, the screen output is based on the already cached citellus results), it's probably not worth at this point to change this

    citellusplugins = []
    # Prefill with all available plugins and the ones we want to filter for
    for extension in extensions:
        citellusplugins.extend(extension.listplugins(options))

    allplugins = citellusplugins

    # By default, flatten plugin list for all extensions
    newplugins = []
    for each in citellusplugins:
        newplugins.extend(each)

    citellusplugins = newplugins

    # Run with all plugins so that we get all data back
    grouped = domagui(sosreports=sosreports, citellusplugins=citellusplugins, options=options)

    # Run Magui plugins
    result = []
    for plugin in magplugs:
        start_time = time.time()
        # Get output from plugin
        data = filterresults(data=grouped, triggers=magtriggers[plugin.__name__.split(".")[-1]])
        returncode, out, err = plugin.run(data=data, quiet=options.quiet)
        updates = {'rc': returncode,
                   'out': out,
                   'err': err}

        adddata = True
        if options.quiet:
            if returncode in [citellus.RC_OKAY, citellus.RC_SKIPPED]:
                adddata = False

        if adddata:
            # If RC is to be stored, process further
            subcategory = os.path.split(plugin.__file__)[0].replace(os.path.join(maguidir, 'plugins', ''), '')

            if subcategory:
                if len(os.path.normpath(subcategory).split(os.sep)) > 1:
                    category = os.path.normpath(subcategory).split(os.sep)[0]
                else:
                    category = subcategory
                    subcategory = ""
            else:
                category = ""

            mydata = {'plugin': plugin.__name__.split(".")[-1],
                      'id': hashlib.md5(plugin.__file__.replace(maguidir, '').encode('UTF-8')).hexdigest(),
                      'description': plugin.help(),
                      'result': updates,
                      'time': time.time() - start_time,
                      'category': category,
                      'subcategory': subcategory}

            result.append(mydata)

    pprint.pprint(result, width=1)


if __name__ == "__main__":
    main()
