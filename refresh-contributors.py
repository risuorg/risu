#!/usr/bin/env python
# encoding: utf-8
#
# Description: Script to update contributors for each plugin
# Copyright (C) 2018 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

# Find files that misses the header:
# for file in $(find . -type f|grep -v .git|grep -v pyc|grep -v .citellus_tests|egrep '(.py|.txt|.yml|.sh)$'); do grep -q "^# Modifications" $file|| echo $file;done

# How to use:
# python setup.py sdist # To create AUTHORS
# ./refresh-contributors.py
# Check results on your git repo and commit a new PR


import subprocess
import re
import citellusclient.shell as citellus
import shutil
import sys
import os.path
import os

regexpyear = '[0-9][0-9][0-9][0-9]-'
regexpemail = '\\<(.*@.*)\\>'

# Find all plugins
print("Finding all possible files to modify...")
#plugins = citellus.findallplugins()
plugins = citellus.findplugins(folders=[os.path.abspath(os.path.dirname(__file__))], executables=False, exclude=['.git', '.tox', '.pyc', '.history', 'doc/templates'], include=['.yml', '.py', '.sh', '.txt'])

os.environ['LANG'] = 'en_US.UTF-8'

# Iterate over found plugins
for plugin in plugins:

    if not 'citellus/plugins' in plugin['plugin']:

        name = ''
        date = ''

        command = "git blame -e %s | awk '{print $2\" \"$3\" \"$4}'|egrep -o '<.*>.*[0-9][0-9][0-9][0-9]-' | sed 's/  */ /g' | cut -d ' ' -f 1-2 | sort -u" % plugin['plugin']

        p = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
        out, err = p.communicate(str.encode('utf8'))
        returncode = p.returncode
        del p

        modifications = {}

        regexyear = re.compile(regexpyear)
        regexemail = re.compile(regexpemail)

        for line in out.split('\n'):
            for field in line.split():
                if '@' in field:
                    name = field.strip()
                if regexyear.match(field):
                    date = field.strip()

            year = date[0:4]

            for elem in ['<', '>', '(', ')']:
                name = name.replace(elem,'')

            if name and name != '' and not name in modifications:
                modifications.update({name:[]})
            if name in modifications:
                if year and year != '' and not year in modifications[name]:
                    modifications[name].append(year)

        modificatstring = ""
        for name in modifications:
            years = ", ".join([v for v in modifications[name]])

            command = "grep -i %s AUTHORS" % name

            p = subprocess.Popen(command.split(" "), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            out, err = p.communicate(str.encode('utf8'))
            returncode = p.returncode
            del p

            newname = out.strip()
            if years.strip() is not None and newname.strip() is not None:
                modificatstring = modificatstring + "\n" + "# Copyright (C) %s %s" % (years, newname)

        modificatstring = modificatstring + "\n"
        modificatstring = modificatstring.strip()

        lines = []
        for line in (l.rstrip() for l in modificatstring.split("\n")):
            if line != '':
                lines.append(line + '\n')
            elif len(lines) >0 and lines[-1] != '\n':
                lines.append(line + '\n')

        modificatstring = "".join(lines)
        modificatstring = modificatstring.strip()

        if modificatstring == '':
            print("\nDEBUG, no modifications to file %s found" % plugin['plugin'])
            print("grep output")
            print(out)
            print("modifications")
            print(modifications)

        elif modificatstring != '':
            # Now modify the file with the new lines
            regexp = '\A# Copyright .*'
            pluginfile = plugin['plugin']
            newpluginfile = "%s.modif" % pluginfile

            with open(pluginfile, 'r') as f:
                lines = []
                first = True
                for line in (l.rstrip() for l in f):
                    if line != '' and first:
                        lines.append(line + '\n')
                        first = False
                    else:
                        lines.append(line + '\n')
                sourceFileContents = "".join(lines)

                matchmodif = False
                with open(newpluginfile, 'w') as fd:
                    newlines = []
                    for line in sourceFileContents.split('\n'):
                        line = "%s\n" % line
                        if re.match(regexp, line):
                            if not matchmodif:
                                line = modificatstring
                                matchmodif = True
                            else:
                                line = None
                        if line:
                            newlines.append(line)

                    lines = []
                    first = True
                    for line in (l.rstrip() for l in newlines):
                        if line == '' and first:
                            first = False
                        else:
                            if line != '' and first:
                                lines.append(line)
                                first = False
                            elif len(lines) >0 and lines[-1] != '\n':
                                lines.append(line)
                            else:
                                lines.append(line)
                    fd.write("\n".join(lines))

            shutil.copymode(pluginfile, newpluginfile)
            shutil.move(newpluginfile, pluginfile)
