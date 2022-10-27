---
modified: "2022-01-26T13:04:03.311Z"
---

[![License](https://img.shields.io/github/license/risuorg/risu.svg)](LICENSE)
![Python Unit Testing](https://github.com/risuorg/risu/workflows/Python%20Unit%20Testing/badge.svg)
[![](https://readthedocs.org/projects/risu/badge/?version=latest)](https://readthedocs.org/projects/risu/builds/ "Read The docs build")
[![Docker Pulls](https://img.shields.io/docker/pulls/risuorg/risu.svg)](https://img.shields.io/docker/pulls/risuorg/risu.svg)
[![codecov](https://codecov.io/gh/risuorg/risu/branch/master/graph/badge.svg)](https://codecov.io/gh/risuorg/risu)
[![Release status](https://img.shields.io/github/release/risuorg/risu.svg)](https://github.com/risuorg/risu/releases)
[![PyPI version](https://badge.fury.io/py/risu.svg)](https://badge.fury.io/py/risu)

<img src="doc/risu.png" width="202" height="202" border=0 align="right">

**Table of contents**

<!-- TOC depthfrom:1 insertanchor:false orderedlist:false -->

- [Introduction](#introduction)
- [Highlights](#highlights)
- [How does it looks like?](#how-does-it-looks-like)
- [Collaborate](#collaborate)
- [Documentation](#documentation)
- [Contact us!!](#contact-us)

<!-- /TOC -->

## Introduction

Risu is a framework to help with system configuration validation on either live system or a `sosreport` snapshot of the filesystem. This empowers the user to quickly troubleshoot known issues found in the system or the ones arising from different settings across a group of systems.

Via execution of 'plugins' it reports status on each one execution against the system that gives you an idea on health status, actual problems or problems that will reveal themselves if no preventive action is taken.

Please if you have any idea on any improvements please do not hesitate to open an issue.

## Highlights

- Plugins written in your language of choice.
- Allows to dump output to json file to be processed by other tools.
  - Allow to visualize html from json output.
  - Check our sample at: [Risu-www](http://htmlpreview.github.io/?https://github.com/risuorg/risu/blob/master/doc/sampleweb/risu.html)
- Ansible playbook support.
- Save / restore default settings

Framework contains additional README for the tools included:

- [Risu](doc/risu.md)
- [Magui](doc/magui.md)

## How does it looks like?

Check how does it look in an execution at:
[![asciicast](https://asciinema.org/a/169814.png)](https://asciinema.org/a/169814)

## Collaborate

- Open issues/feature requests, etc at <https://github.com/risuorg/risu/issues>
- Read the [Contributing](https://risu.readthedocs.org/en/latest/development/CONTRIBUTING/) document on how to submit patches
- Provide the sosreports to check against via <https://www.dropbox.com/request/8LGneF9i9nc9RB6aqXge>, specially if running Debian based distributions and or Fedora/CentOS based ones so that we can improve support for it

## Documentation

Documentation is available at [Read the docs](https://risu.readthedocs.org)

## Contact us!!

You can reach to us via:

- irc at #risu in [Libera](https://libera.chat/)
- our mailing list:
  - <mailto:risuorg _AT_ googlegroups.com>
  - <https://groups.google.com/forum/#!forum/risu>
