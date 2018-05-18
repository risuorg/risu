[![License](https://img.shields.io/github/license/citellusorg/citellus.svg)](LICENSE)
[![Build Status](https://travis-ci.org/citellusorg/citellus.svg?branch=master)](https://travis-ci.org/citellusorg/citellus)
[![Coverage Status](https://coveralls.io/repos/github/citellusorg/citellus/badge.svg?branch=master)](https://coveralls.io/github/citellusorg/citellus?branch=master)
[![Release status](https://img.shields.io/github/release/citellusorg/citellus.svg)](https://github.com/citellusorg/citellus/releases)
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
    - Check our sample at: [Citellus-www](http://htmlpreview.github.io/?https://github.com/citellusorg/citellus/blob/master/doc/sampleweb/citellus.html)
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

- Give it a try running as 'root' on your system with: `./citellus.py -l -F"` so it will show `live execution` and only `Failed` tests.

## How does it looks like?
Check how does it look in an execution at:
[![asciicast](https://asciinema.org/a/169814.png)](https://asciinema.org/a/169814)

## HTML Interface
<img src="doc/images/www.png" width="95%" border=0>

## Additional resources

- Devconf.cz 2018 Presentation:
    - Slot link [devconf.cz 2018!!](https://devconfcz2018.sched.com/event/DJXG/detect-pitfalls-of-osp-deployments-with-citellus)
    - Slides: <doc/devconfcz2018-presentation-revealmd.md>
    - Recording <https://www.youtube.com/watch?v=SDzzqrUdn5A>
- SuperSec 2018 Presentation:
    - Slot link: <https://supersec.es/programa/>
    - Slides: <doc/supersec2018-presentation-ES.md>
    - Recording:  not yet available
- Blog posts
    - Citellus.org <https://citellus.org/>
    - Pablo Iranzo's Blog: <https://iranzo.github.io/blog/tag/citellus/>
        - <https://iranzo.github.io/blog/2017/07/26/Citellus-framework-for-detecting-known-issues/>
        - <https://iranzo.github.io/blog/2017/07/31/Magui-for-analysis-of-issues-across-several-hosts/>
        - <https://iranzo.github.io/blog/2017/08/17/Jenkins-for-running-CI-tests/>
        - <https://iranzo.github.io/blog/2017/10/26/i18n-and-bash8-in-bash/>
        - <https://iranzo.github.io/blog/2018/01/16/recent-changes-in-magui-and-citellus/>

## Collaborate

- Open issues/feature requests, etc at <https://github.com/citellusorg/citellus/issues>
- Read the [Contributing](CONTRIBUTING.md) document on how to submit patches
- Provide sosreports to check against via <https://www.dropbox.com/request/8LGneF9i9nc9RB6aqXge>, specially if running Debian based distributions and or Fedora/CentOS based ones so that we can improve support for it

## Documentation

| Documentation | Additional Notes |
|---|---|
|[Changelog](Changelog.md)| for everyone|
|[Citellus](README.citellus.md) | for everyone |
|[Magui](README.magui.md) | for everyone |
|[General presentation](doc/presentation-revealmd.md)|for everyone|
|[Devconf.cz 2018 presentation](doc/devconfcz2018-presentation-revealmd.md)|for everyone|
|[Reviewer](REVIEWER.md)|for code reviewers|
|[Contributing](CONTRIBUTING.md) | for plugin developers |
|[Testing](TESTING.md) | for plugin developers: writing Unit Testing for plugins|
|[internationalization i18n](doc/i18n.md)|for plugin developers|
|[Ansible playbooks](doc/ansible-playbooks.md)| for plugin developers|
|[Extensions documentation](doc/extensions-documentation.md)|for plugin developers|
|[Extension development](doc/extension-development.md)|for extension developers willing to extend citellus plugin system|
|[Magui plugin development](doc/magui-plugin-development.md)|for Magui plugin developers|

## Contact us!!
You can reach to us via:
- irc at #citellus in Freenode
- our mailing list:
    - <mailto:citellus-dev _AT_ redhat.com>
    - <https://www.redhat.com/mailman/listinfo/citellus-dev>
