[![License](https://img.shields.io/github/license/zerodayz/citellus.svg)](LICENSE)
[![Build Status](https://travis-ci.org/zerodayz/citellus.svg?branch=master)](https://travis-ci.org/zerodayz/citellus)
[![Coverage Status](https://coveralls.io/repos/github/zerodayz/citellus/badge.svg?branch=master)](https://coveralls.io/github/zerodayz/citellus?branch=master)
[![Release status](https://img.shields.io/github/release/zerodayz/citellus.svg)](https://github.com/zerodayz/citellus/releases)
[![PyPI version](https://badge.fury.io/py/citellus.svg)](https://badge.fury.io/py/citellus)
[![](https://images.microbadger.com/badges/image/citellus/citellus.svg)](https://microbadger.com/images/citellus/citellus "Get your own image badge on microbadger.com")

<img src="doc/citellus.png" width="20%" border=0 align="right">

# Introduction

Citellus is a framework to help with system configuration validation on either live system or any sort of snapshot of the filesystem.

Via execution of 'plugins' it reports status on each one execution against the system that gives you an idea on health status, actual problems or problems that will reveal themselves if no preventive action is taken.

Please if you have any idea on any improvements please do not hesitate to open an issue.

## Highlights
- Plugins written in your language of choice.
- Allows to dump output to json file to be processed by other tools.
    - Allow to visualize html from json output.
    - Check our sample at: [Citellus-www](http://htmlpreview.github.io/?https://github.com/zerodayz/citellus/blob/master/doc/sampleweb/citellus.html)
- Ansible playbook support.
- Save / restore default settings

Check latest changes on [Changelog.md](Changelog.md)

Check for plugins listing on [citellusclient/plugins/](citellusclient/plugins/)

Framework contains additional readmes for the tools included:

- [Citellus README](README.citellus.md)
- [Magui README](README.magui.md)

## Installation

Check `README` above for detailed instructions outside os simple ones:
- Just clone the git repository and execute it from there 'or'
- use 'pipsi' or create a python virtual env to install package 'citellus'

## How does it looks like?
Check how does it look in an execution at:
[![asciicast](https://asciinema.org/a/169814.png)](https://asciinema.org/a/169814)

## HTML Interface
<img src="doc/images/www.png" height="40%" border=0>

## Additional resources

- Devconf.cz 2018 Presentation:
    - Slot link [devconf.cz 2018!!](https://devconfcz2018.sched.com/event/DJXG/detect-pitfalls-of-osp-deployments-with-citellus)
    - Slides <doc/devconfcz2018-presentation-revealmd.md>
    - Recording <https://www.youtube.com/watch?v=SDzzqrUdn5A>
- Blog posts
    - <https://iranzo.github.io/blog/2017/07/26/Citellus-framework-for-detecting-known-issues/>
    - <https://iranzo.github.io/blog/2017/07/31/Magui-for-analysis-of-issues-across-several-hosts/>
    - <https://iranzo.github.io/blog/2017/08/17/Jenkins-for-running-CI-tests/>
    - <https://iranzo.github.io/blog/2017/10/26/i18n-and-bash8-in-bash/>
    - <https://iranzo.github.io/blog/2018/01/16/recent-changes-in-magui-and-citellus/>

## Contact us!!
You can reach to us via:
- irc at #citellus in Freenode
- our mailing list:
    - <mailto:citellus-dev@redhat.com>
    - <https://www.redhat.com/mailman/listinfo/citellus-dev>
