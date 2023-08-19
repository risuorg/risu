#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Description: Script to update contributors for each plugin
# Copyright (C) 2018-2023 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

# Find files that misses the header:
# for file in $(find . -type f|grep -v .git|grep -v pyc|grep -v .risu_tests|grep -E '(.py|.txt|.yml|.sh)$'); do grep -q "^# Modifications" $file|| echo $file;done

# How to use:
# python setup.py sdist # To create AUTHORS
# ./refresh-contributors.py
# Check results on your git repo and commit a new PR


import os
import re
import shutil
import subprocess
import sys

import risuclient.shell as risu


def getranges(data):
    """
    From list of strings representing numbers, get ranges and return list of strings
    :param data: list of strings representing numbers
    :return: list of strings with number ranges when > 1
    """

    # Convert to integers
    data = [int(i) for i in data]

    result = []
    if not data:
        return result

    # Prepare iteration loop
    idata = iter(data)
    first = prev = next(idata)
    first = first
    prev = prev

    # Process next item
    for following in idata:
        if following - prev == 1:
            # Years are continuum, just update previous
            prev = following
        else:
            # Years are not continuum, end range and start again
            if first == prev:
                result.append(first)
            else:
                if first + 1 == prev:
                    # Only one item in difference, append items individually
                    result.append(first)
                    result.append(prev)
                else:
                    result.append("%s-%s" % (first, prev))
            first = prev = following

    # Catchall for regular execution or last remaining range

    if first == prev:
        result.append(first)
    else:
        if first + 1 == prev:
            # Only one item in difference, append items individually
            result.append(first)
            result.append(prev)
        else:
            result.append("%s-%s" % (first, prev))

    # Convert back to text
    result = [str(i) for i in result]
    return result


def main():
    # Find all plugins
    print("Finding all possible files to modify...")
    # plugins = risu.findallplugins()
    plugins = risu.findplugins(
        folders=[os.path.abspath(os.path.dirname(__file__))],
        executables=False,
        exclude=[".git", ".tox", ".pyc", ".history", "doc/templates", ".eggs"],
        include=[".yml", ".py", ".sh", ".txt"],
    )

    os.environ["LANG"] = "en_US.UTF-8"

    # Iterate over found plugins
    for plugin in plugins:
        if "risu/plugins" not in plugin["plugin"]:
            name = ""
            date = ""

            command = (
                "cd $(dirname %s) && git blame -C -M -w -e %s | awk '{print $2\" \"$3\" \"$4}'|grep -E -o '<.*>.*[0-9][0-9][0-9][0-9]-' | sed 's/  */ /g' | cut -d ' ' -f 1-2 | sort -u|grep -v not.committed.yet"
                % (plugin["plugin"], plugin["plugin"])
            )

            p = subprocess.Popen(
                command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True
            )
            out, err = p.communicate(str.encode("utf8"))

            del p
            out = out.decode("utf-8")

            modifications = {}

            regexyear = re.compile("[0-9][0-9][0-9][0-9]-")
            # regexemail = re.compile("\\<(.*@.*)\\>")

            if out:
                for line in out.split("\n"):
                    for field in line.split():
                        if "@" in field:
                            name = field.strip()
                        if regexyear.match(field):
                            date = field.strip()

                    year = date[0:4]

                    for elem in ["<", ">", "(", ")"]:
                        name = name.replace(elem, "")

                    if name and name != "" and name not in modifications:
                        modifications.update({name: []})
                    if name in modifications and (
                        year and year != "" and year not in modifications[name]
                    ):
                        modifications[name].append(year)

            modificatstring = ""
            for name in modifications:
                yearslist = [v for v in modifications[name]]
                if len(yearslist) > 1:
                    # Get rangs of years for pretty printing them
                    yearslist = getranges(yearslist)

                years = ", ".join(yearslist)

                command = "grep -i %s AUTHORS" % name

                p = subprocess.Popen(
                    command.split(" "), stdout=subprocess.PIPE, stderr=subprocess.PIPE
                )
                out, err = p.communicate(str.encode("utf8"))
                out = out.decode("utf-8")

                del p

                newname = out.strip()
                if years.strip() is not None and newname.strip() is not None:
                    modificatstring = (
                        modificatstring
                        + "\n"
                        + "# Copyright (C) %s %s" % (years, newname)
                    )

            if len(newname.split("\n")) > 1:
                print(
                    "\nERROR: Probably user is not defined in .mailmap. Update .mailmap, rerun python setup.py sdist and then this script"
                )
                print("")
                print("FILE: %s" % plugin["plugin"])
                print("-------")
                print(newname)
                print("-------")
                sys.exit(-1)

            modificatstring = modificatstring + "\n"
            modificatstring = modificatstring.strip()

            lines = []
            for line in (pline.rstrip() for pline in modificatstring.split("\n")):
                if line != "":
                    lines.append(line + "\n")
                elif len(lines) > 0 and lines[-1] != "\n":
                    lines.append(line + "\n")

            modificatstring = "".join(lines)
            modificatstring = modificatstring.strip()

            if modificatstring == "":
                print("\nDEBUG, no modifications to file %s found" % plugin["plugin"])
                print("grep output:")
                print(out)
                print("modifications:")
                print(modifications)

            elif modificatstring != "":
                # Now modify the file with the new lines
                regexp = r"\A# Copyright .*"
                pluginfile = plugin["plugin"]
                newpluginfile = "%s.modif" % pluginfile

                with open(pluginfile, "r") as f:
                    lines = []
                    first = True
                    for line in (pline.rstrip() for pline in f):
                        if line != "" and first:
                            lines.append(line + "\n")
                            first = False
                        else:
                            lines.append(line + "\n")
                    sourceFileContents = "".join(lines)

                    matchmodif = False
                    with open(newpluginfile, "w") as fd:
                        newlines = []
                        for line in sourceFileContents.split("\n"):
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
                        for line in (pline.rstrip() for pline in newlines):
                            if line == "" and first:
                                first = False
                            else:
                                if line != "" and first:
                                    lines.append(line)
                                    first = False
                                elif len(lines) > 0 and lines[-1] != "\n":
                                    lines.append(line)
                                else:
                                    lines.append(line)
                        fd.write("\n".join(lines))

                shutil.copymode(pluginfile, newpluginfile)
                shutil.move(newpluginfile, pluginfile)


if __name__ == "__main__":
    sys.exit(main())
