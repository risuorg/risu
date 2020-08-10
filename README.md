[![License](https://img.shields.io/github/license/citellusorg/citellus.svg)](LICENSE)
![Python Unit Testing](https://github.com/citellusorg/citellus/workflows/Python%20Unit%20Testing/badge.svg)
[![Build Status](https://travis-ci.org/citellusorg/citellus.svg?branch=master)](https://travis-ci.org/citellusorg/citellus)
[![](https://readthedocs.org/projects/citellus/badge/?version=latest)](https://readthedocs.org/projects/citellus/builds/ "Read The docs build")
[![Docker Pulls](https://img.shields.io/docker/pulls/citellus/citellus.svg)](https://img.shields.io/docker/pulls/citellus/citellus.svg)
[![codecov](https://codecov.io/gh/citellusorg/citellus/branch/master/graph/badge.svg)](https://codecov.io/gh/citellusorg/citellus)
[![Release status](https://img.shields.io/github/release/citellusorg/citellus.svg)](https://github.com/citellusorg/citellus/releases)
[![PyPI version](https://badge.fury.io/py/citellus.svg)](https://badge.fury.io/py/citellus)
[![](https://images.microbadger.com/badges/image/citellus/citellus.svg)](https://microbadger.com/images/citellus/citellus "Get your own image badge on microbadger.com")
<a href="https://t.me/citellusUG"><img src="https://img.shields.io/badge/Citellus%20User%20Group-190cde.svg?logo=telegram" alt="Citellus User Group on Telegram"/></a>

<img src="doc/citellus.png" width="202" height="202" border=0 align="right">

**Table of contents**

<!-- TOC depthFrom:1 insertAnchor:false orderedList:false -->

- [Introduction](#introduction)
- [Highlights](#highlights)
- [How does it looks like?](#how-does-it-looks-like)
- [Collaborate](#collaborate)
- [Documentation](#documentation)
- [Contact us!!](#contact-us)

<!-- /TOC -->

## Introduction

Citellus is a framework to help with system configuration validation on either live system or a `sosreport` snapshot of the filesystem. This empowers the user to quickly troubleshoot known issues found in the system or the ones arising from different settings across a group of systems.

Via execution of 'plugins' it reports status on each one execution against the system that gives you an idea on health status, actual problems or problems that will reveal themselves if no preventive action is taken.

Please if you have any idea on any improvements please do not hesitate to open an issue.

## Highlights

- Plugins written in your language of choice.
- Allows to dump output to json file to be processed by other tools.
  - Allow to visualize html from json output.
  - Check our sample at: [Citellus-www](http://htmlpreview.github.io/?https://github.com/citellusorg/citellus/blob/master/doc/sampleweb/citellus.html)
- Ansible playbook support.
- Save / restore default settings

Framework contains additional readmes for the tools included:

- [Citellus](citellus.md)
- [Magui](magui.md)

## How does it looks like?

Check how does it look in an execution at:
[![asciicast](https://asciinema.org/a/169814.png)](https://asciinema.org/a/169814)

## Collaborate

- Open issues/feature requests, etc at <https://github.com/citellusorg/citellus/issues>
- Read the [Contributing](https://docs.citellus.org/en/latest/development/CONTRIBUTING/) document on how to submit patches
- Provide sosreports to check against via <https://www.dropbox.com/request/8LGneF9i9nc9RB6aqXge>, specially if running Debian based distributions and or Fedora/CentOS based ones so that we can improve support for it

## Documentation

Documentation is available at [Read the docs](https://docs.citellus.org)

## Contact us!!

You can reach to us via:

- irc at #citellus in Freenode
- Telegram at <https://t.me/citellusUG>
- our mailing list:
  - <mailto:citellus _AT_ googlegroups.com>
  - <https://groups.google.com/forum/#!forum/citellus>
