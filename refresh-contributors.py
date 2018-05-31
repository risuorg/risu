#!/usr/bin/env python
# encoding: utf-8
#
# Description: Script to update contributors for each plugin
#
# Copyright (C) 2018 Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)

import subprocess
import re
import citellusclient.shell as citellus
#from citellusclient import shell as citellus


regexpyear = '([0-9][0-9][0-9][0-9])-'
regexpemail = '\\<(.*@.*)\\>'

plugins = citellus.findallplugins()
#plugins = [{'plugin':'/home/iranzo/DEVEL/citellus/citellus/citellusclient/plugins/metadata/system/sosreport-date.sh'}]

for plugin in plugins:
    name = ''
    date = ''

    command = "git blame -e %s" % plugin['plugin']

    p = subprocess.Popen(command.split(" "), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    out, err = p.communicate(str.encode('utf8'))
    returncode = p.returncode
    del p

    modifications = {}

    regexyear = re.compile(regexpyear)
    regexemail = re.compile(regexpemail)
    for line in out.split('\n'):
        for field in line.split():
            if '@' in field and '<' in field and '(' in field:
                name = field.strip()
            if regexyear.match(field):
                date = field.strip()

        year = date[0:4]

        for elem in ['<', '>', '(', ')']:
            name = name.replace(elem,'')

        if not name in modifications:
            modifications.update({name:[]})
        if not year in modifications[name]:
            modifications[name].append(year)

    modificatstring = ""
    for name in modifications:
        years = ", ".join([v for v in modifications[name]])

        command = "grep %s AUTHORS" % name

        p = subprocess.Popen(command.split(" "), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        out, err = p.communicate(str.encode('utf8'))
        returncode = p.returncode
        del p

        newname = out.strip()
        modificatstring = modificatstring + "\n" + "#    Modifications (%s) by %s" % (years, newname)


    print plugin['plugin'], modificatstring
