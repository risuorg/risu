[![License](https://img.shields.io/github/license/risuorg/risu.svg)](LICENSE)
[![](https://readthedocs.org/projects/risu/badge/?version=latest)](https://readthedocs.org/projects/risu/builds/ "Read The docs build")
[![codecov](https://codecov.io/gh/risuorg/risu/branch/master/graph/badge.svg)](https://codecov.io/gh/risuorg/risu)
[![Release status](https://img.shields.io/github/release/risuorg/risu.svg)](https://github.com/risuorg/risu/releases)
[![PyPI version](https://badge.fury.io/py/risu.svg)](https://badge.fury.io/py/risu)

<img src="risu.png" width="202" height="202" border=0 align="right">

**Table of contents**

<!-- TOC depthFrom:1 insertAnchor:false orderedList:false -->

- [Introduction](#introduction)
- [Highlights](#highlights)
- [Installation](#installation)
- [How does it looks like?](#how-does-it-looks-like)
- [HTML Interface](#html-interface)
- [Additional resources](#additional-resources)
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
  - Check our sample at: [Risu-www](https://risuorg.github.io/risu.html)
- Ansible playbook support.
- Save / restore default settings

Framework contains additional readmes for the tools included:

- [Risu](risu.md)
- [Magui](magui.md)

## Installation

Check `README` above for detailed instructions outside os simple ones:

- Just clone the git repository and execute it from there 'or'
- use 'pipsi' or create a python virtual env to install package 'risu'

- Give it a try running as 'root' on your system with: `./risu.py -l` so it will show `live execution` and only `Failed` tests.

## How does it looks like?

Check how does it look in an execution at:
[![asciicast](https://asciinema.org/a/169814.png)](https://asciinema.org/a/169814)

## HTML Interface

<img src="images/www.png" width="95%" border=0>

## Additional resources

- Devconf.cz 2018 Presentation:
  - Slot link [devconf.cz 2018!!](https://devconfcz2018.sched.com/event/DJXG/detect-pitfalls-of-osp-deployments-with-risu)
  - Slides: <devconfcz2018-presentation-revealmd.md>
  - Recording <https://www.youtube.com/watch?v=SDzzqrUdn5A>
- SuperSec 2018 Presentation:
  - Slot link: <https://supersec.es/programa/>
  - Slides: <supersec2018-presentation-ES.md>
  - Recording: not yet available
- Blog posts
  - Risu.org <https://risuorg.github.io/>
  - Pablo Iranzo's Blog: <https://iranzo.github.io/blog/tag/risu/>
    - <https://iranzo.github.io/blog/2017/07/26/Risu-framework-for-detecting-known-issues/>
    - <https://iranzo.github.io/blog/2017/07/31/Magui-for-analysis-of-issues-across-several-hosts/>
    - <https://iranzo.github.io/blog/2017/08/17/Jenkins-for-running-CI-tests/>
    - <https://iranzo.github.io/blog/2017/10/26/i18n-and-bash8-in-bash/>
    - <https://iranzo.github.io/blog/2018/01/16/recent-changes-in-magui-and-risu/>

## Collaborate

- Open issues/feature requests, etc at <https://github.com/risuorg/risu/issues>
- Read the [Contributing](development/CONTRIBUTING.md) document on how to submit patches
- Provide sosreports to check against via <https://www.dropbox.com/request/8LGneF9i9nc9RB6aqXge>, specially if running Debian based distributions and or Fedora/CentOS based ones so that we can improve support for it

## Documentation

Documentation is available at [Read the docs](https://risu.readthedocs.io)

## Contact us!!

You can reach to us via:

- irc at #risu in [Libera](https://libera.chat/)
- our mailing list:
  - <mailto:risuorg _AT_ googlegroups.com>
  - <https://groups.google.com/forum/#!forum/risu>
