#!/usr/bin/env python
# encoding: utf-8
#
# Description: Multiple Analysis Generic Unifier and Interpreter aka Magui
#              This program processes several snapshoot/sosreport files
#              and processes citellus output for combined issues via plugins
#              that search for specific plugin and data
#
# Copyright (C) 2018 David Sastre Medina <d.sastre.medina@gmail.com>
# Copyright (C) 2017, 2018 Robin Černín <cerninr@gmail.com>
# Copyright (C) 2017, 2018 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>
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
import copy
import gettext
import glob
import hashlib
import logging
import os.path
import shutil
import sys
import time

sys.path.append(os.path.abspath(os.path.dirname(__file__) + '/' + '../'))

from citellusclient import shell as citellus

LOG = logging.getLogger('magui')

# Where are we?
maguidir = os.path.abspath(os.path.dirname(__file__))
localedir = os.path.join(citellus.citellusdir, 'locale')

global PluginsFolder
PluginsFolder = os.path.join(maguidir, "plugins")

global MaguiHooksFolder
MaguiHooksFolder = os.path.join(maguidir, "hooks")

global plugins
plugins = []
global plugtriggers
plugtriggers = {}
global maguihooks
maguihooks = []

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

    logo = r"    _    ", \
           r"  _( )_  Magui:", \
           r" (_(ø)_) ", \
           r"  /(_)   Multiple Analisis Generic Unifier and Interpreter", \
           r" \|      ", \
           r"  |/     ", \
           r""
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
                   help=_("Write results to JSON file FILENAME"),
                   default='magui.json')
    p.add_argument("--run", "-r",
                   action='store_true',
                   help=_("Force run of citellus instead of reading existing 'citellus.json'"))
    p.add_argument("--hosts",
                   metavar="hosts",
                   help=_("Gather data via ansible from remote hosts to process."))

    p.add_argument("--max-hosts",
                   default=10,
                   metavar="max-hosts",
                   help=_("Define the number of maximum simultaneous hosts checks"))

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
    g.add_argument("--anon", dest='anon',
                   action="store_true",
                   help=_("Anonymize output"))
    g.add_argument("--lang",
                   help=_("Define locale to use"),
                   default='en_US')
    g.add_argument("--call-home", default=False, help=_("Server URI to HTTP-post upload generated citellus.json for metrics"), metavar='serveruri')

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
    results = citellus.docitellus(path=path, plugins=plugins, forcerun=forcerun, include=include, exclude=exclude, quiet=True)

    # Process plugin output from multiple plugins to be returned as a dictionary of ID's for each plugin
    new_dict = {}
    for item in results:
        name = results[item]['id']
        new_dict[name] = dict(results[item])
    del results

    # cleanup new_dict of unused data
    # trimmed = {}
    # for item in new_dict:
    #     trimmed[item] = {}
    #     # 'id', 'plugin', 'backend', 'path', 'name',
    #     for key in ['result']:
    #         if key in new_dict[item]:
    #             trimmed[item][key] = new_dict[item][key]

    # del new_dict

    return new_dict


def findtarget(data):
    """
    Sorts autogroup to find next target to reduce memory usage and data reuse
    :param data: autogroup dictionary
    :return: array made of target, data and elem to del (if any)
    """

    target = ''
    todel = False

    subitemcount = {}
    # Find subitems

    for item in data:
        for subitem in data[item]:
            if subitem not in subitemcount:
                subitemcount[subitem] = {'count': 1, 'where': [item]}
            else:
                subitemcount[subitem]['count'] = 1 + subitemcount[subitem]['count']
                subitemcount[subitem]['where'].append(item)

    minitems = subitemcount

    for item in subitemcount:
        if subitemcount[item]['count'] < minitems:
            target = subitemcount[item]['where'][0]
            minitems = subitemcount[item]['count']
            if minitems == 1:
                todel = item
                break

    return target, data, todel


def domagui(sosreports, citellusplugins, options=False, grouped={}, runhooks=True):
    """
    Do actual execution against sosreports
    :return: dict of result
    """

    if grouped != {}:
        # Cleanup grouped for sosreports we're not interested at all
        cleansosreports = []

        for plugin in grouped:
            # Walk plugins
            for sosreport in grouped[plugin]['sosreport']:
                # Walk sosreports for plugin
                if sosreport not in sosreports:
                    # Add sosreport to cleanup list
                    cleansosreports.append(sosreport)

        for sosreport in sorted(set(cleansosreports)):
            for plugin in grouped:
                if sosreport in grouped[plugin]['sosreport']:
                    del grouped[plugin]['sosreport'][sosreport]
    else:
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
                    # Skip composed plugins as they will cause rerun
                    if '-' not in plugin:
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

    if runhooks:
        # Run the hook processing hooks on the results
        for maguihook in citellus.initPymodules(extensions=citellus.getPymodules(options=options, folders=[MaguiHooksFolder]))[0]:
            LOG.debug("Running hook: %s" % maguihook.__name__.split('.')[-1])
            newresults = maguihook.run(data=copy.deepcopy(grouped))
            if newresults:
                grouped = newresults

    # We've now a matrix of grouped[plugin][sosreport] and then [text] [out] [err] [rc]
    return grouped


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
            if 'id' in data[elem]:
                if trigger in data[elem]['id']:
                    ourdata[data[elem]['id']] = dict(data[elem])
    return ourdata


def autogroups(autodata):
    """
    Based on metadata-outputs plugin generate possible groups for sosreport combination
    :param autodata: metadata-outputs reults
    :return: dict of groups and members
    """
    # Prefill dict with hosts
    hostsdict = {}
    for item in autodata:
        for elem in iter(item['sosreport'].keys()):
            if elem not in hostsdict:
                hostsdict[elem] = {}

        name = item['name']
        for host in item['sosreport']:
            if item['sosreport'][host]['rc'] == citellus.RC_OKAY:
                value = item['sosreport'][host]['err']
            else:
                value = ''
            if value != '':
                update = {name: value}
                hostsdict[host].update(update)

    # At this point we have a dict of dicts, being at first level the host with the output of the metadata, similar to:
    # print(hostsdict)={'host1': {'release': 'xxxx', 'UUID': 'YYYYY'}, 'host2': .... }

    groups = {}

    # Precreate groups
    for element in hostsdict:
        for item in iter(hostsdict[element].items()):
            if not item[0] in groups:
                groups["%s" % item[0]] = {}
            if not item[1] in groups["%s" % item[0]]:
                groups["%s" % item[0]]["%s" % item[1]] = [element]
            else:
                groups["%s" % item[0]]["%s" % item[1]].append(element)

    results = {}
    for category in groups:
        for subcategory in groups[category]:
            name = "%s-%s" % (category, subcategory)
            if 1 < len(groups[category][subcategory]) < len(hostsdict):
                results[name] = groups[category][subcategory]

    # Here we've a list of groups based on 'metadata' plugin name and the hosts in the same group if more than one host.
    #
    #  {u'5:system-role-node': ['sosreport-apps1.lab.example.com-20180928160549',
    #                        'sosreport-infra1.lab.example.com-20180928160443',
    #                        'sosreport-infra3.lab.example.com-20180928160521',
    #                        'sosreport-apps2.lab.example.com-20180928160605',
    #                        'sosreport-infra2.lab.example.com-20180928160506'],
    #  u'system-role-master': ['sosreport-master1.lab.example.com-20180928155907',
    #                          'sosreport-master2.lab.example.com-20180928160411',
    #                          'sosreport-master3.lab.example.com-20180928160415']}

    return results


def main():
    """
    Main code stub
    """

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

    magplugs, magtriggers = citellus.initPymodules(extensions=citellus.getPymodules(options=options, folders=[PluginsFolder]))

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
        extensions = citellus.initPymodules()[0]
    else:
        extensions = citellus.extensions

    # Grab the data
    sosreports = options.sosreports

    # If we've provided a hosts file, use ansible to grab the data from them
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

            LOG.debug("Running: %s with 600 seconds timeout" % command)
            citellus.execonshell(filename=command, timeout=600)

            # Now check the hosts we got logs from:
            hosts = citellus.findplugins(folders=glob.glob('/tmp/citellus/hostrun/*'), executables=False, fileextension='.json')
            for host in hosts:
                sosreports.append(os.path.dirname(host['plugin']))

    # Get all data from hosts for all plugins, etc
    if options.output:
        dooutput = options.output
    else:
        dooutput = False

    if len(sosreports) > options.max_hosts:
        print("Maximum number of sosreports provided, exiting")
        sys.exit(0)

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

    def runmaguiandplugs(sosreports, citellusplugins, filename=dooutput, extranames=None, serveruri=False, onlysave=False, result=None, anon=False, grouped={}):
        """
        Runs magui and magui plugins
        :param grouped: Grouped results from sosreports to speedup processing (domagui)
        :param anon: anonymize results on execution
        :param serveruri: Server uri to POST the analysis
        :param sosreports: sosreports to process
        :param citellusplugins: citellusplugins to run
        :param filename: filename to save to
        :param extranames: additional filenames used
        :param onlysave: Bool: Defines if we just want to save results
        :param result: Results to write to disk
        :return: results of execution
        """

        start_time = time.time()
        if not onlysave and not result:
            # Run with all plugins so that we get all data back
            grouped = domagui(sosreports=sosreports, citellusplugins=citellusplugins, grouped=grouped)

            # Run Magui plugins
            result = []
            for plugin in magplugs:
                plugstart_time = time.time()
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
                          'id': hashlib.sha512(plugin.__file__.replace(maguidir, '').encode('UTF-8')).hexdigest(),
                          'description': plugin.help(),
                          'long_name': plugin.help(),
                          'result': updates,
                          'time': time.time() - plugstart_time,
                          'category': category,
                          'subcategory': subcategory}

                result.append(mydata)
        if filename:
            branding = _("                                                  ")
            citellus.write_results(results=result, filename=filename, source='magui', path=sosreports, time=time.time() - start_time, branding=branding, web=True, extranames=extranames, serveruri=serveruri, anon=anon)

        return result, grouped

    print(_("\nStarting check updates and comparison"))

    metadataplugins = []
    for plugin in citellusplugins:
        if plugin['backend'] == 'metadata':
            metadataplugins.append(plugin)

    # Prepare metadata execution to find groups
    results, grouped = runmaguiandplugs(sosreports=sosreports, citellusplugins=metadataplugins, filename=options.output, serveruri=options.call_home)

    # Now we've Magui saved for the whole execution provided in 'results' var

    # Start working on autogroups
    for result in results:
        if result['plugin'] == 'metadata-outputs':
            autodata = result['result']['err']

    print(_("\nGenerating autogroups:\n"))

    groups = autogroups(autodata)
    processedgroups = {}

    # TODO(iranzo): Review this
    # This code was used to provide a field in json for citellus.html to get
    # other groups in dropdown, but is not in use so commenting meanwhile

    filenames = []

    # loop over filenames first so that full results are saved and freed from memory
    for group in groups:
        basefilename = os.path.splitext(options.output)
        filename = basefilename[0] + "-" + group + basefilename[1]
        runautogroup = True
        for progroup in processedgroups:
            if sorted(set(groups[group])) == sorted(set(processedgroups[progroup])):
                runautogroup = False
                runautofile = progroup
        if runautogroup:
            # Analysis will be generated
            filenames.append(filename)

    print("\nRunning full comparison:... %s" % options.output)

    # Run full (not only metadata plugins) so that we've the data stored and save filenames in magui.json
    results, grouped = runmaguiandplugs(sosreports=sosreports, citellusplugins=citellusplugins, extranames=filenames, filename=options.output, serveruri=options.call_home)

    # Here 'grouped' obtained from above contains the full set of data

    # Results stored, removing variable to free up memory
    del results

    # reset list of processed groups

    # while len(data) != 0:
    #     print "loop: ", loop
    #     loop = loop +1
    #     target, data, todel = findtarget(data)

    processedgroups = {}
    basefilename = os.path.splitext(options.output)

    while len(groups) != 0:
        target, newgroups, todel = findtarget(groups)
        group = target
        filename = basefilename[0] + "-" + group + basefilename[1]
        print(_("\nRunning for group: %s" % filename))
        runautogroup = True

        for progroup in processedgroups:
            if groups[target] == processedgroups[progroup]:
                runautogroup = False
                runautofile = progroup

        if runautogroup:
            # Analysis was missing for this group, run it
            # pass grouped as 'dict' to avoid mutable
            newgrouped = copy.deepcopy(grouped)
            runmaguiandplugs(sosreports=groups[target], citellusplugins=citellusplugins, filename=filename, extranames=filenames, anon=options.anon, grouped=newgrouped)
        else:
            # Copy file instead of run as it was already existing
            LOG.debug("Copying old file from %s to %s" % (runautofile, filename))
            shutil.copyfile(runautofile, filename)

        processedgroups[filename] = groups[target]

        if todel:
            # We can remove a sosreport from the dataset
            for plugin in grouped:
                if todel in grouped[plugin]['sosreport']:
                    del grouped[plugin]['sosreport'][todel]

        del newgroups[target]
        # Put remaining groups to work
        groups = dict(newgroups)

    del groups
    del processedgroups

    print(_("\nFinished autogroup generation."))


if __name__ == "__main__":
    main()
