.. image:: https://img.shields.io/github/license/citellusorg/citellus.svg :alt: LICENSE
.. image:: https://travis-ci.org/citellusorg/citellus.svg?branch=master :alt:  Build Status
.. image:: https://coveralls.io/repos/github/citellusorg/citellus/badge.svg?branch=master :alt:  Coverage Status
.. image:: https://img.shields.io/github/release/citellusorg/citellus.svg :alt:  Releases
.. image:: https://badge.fury.io/py/citellus.svg :alt:  Pypi version
.. image:: https://images.microbadger.com/badges/image/citellus/citellus.svg :alt:  Microbadger


Introduction
============

Citellus is a framework to help with system configuration validation on
either live system or any sort of snapshot of the filesystem.

Via execution of ‘plugins’ it reports status on each one execution
against the system that gives you an idea on health status, actual
problems or problems that will reveal themselves if no preventive action
is taken.

Please if you have any idea on any improvements please do not hesitate
to open an issue.

Highlights
----------

-  Plugins written in your language of choice.
-  Allows to dump output to json file to be processed by other tools.

   -  Allow to visualize html from json output.
   -  Check our sample at: `Citellus-www`_

-  Ansible playbook support.
-  Save / restore default settings

Check latest changes on `Changelog.md`_

Check for plugins listing on `citellusclient/plugins/`_

Framework contains additional readmes for the tools included:

-  `Citellus README`_
-  `Magui README`_

Installation
------------

Check ``README`` above for detailed instructions outside os simple ones:
- Just clone the git repository and execute it from there ‘or’ - use
‘pipsi’ or create a python virtual env to install package ‘citellus’

-  Give it a try running as ‘root’ on your system with:
   ``./citellus.py -l`` so it will show ``live execution`` and only
   ``Failed`` tests.

How does it looks like?
-----------------------

Check how does it look in an execution at: `asciicast`_


Additional resources
--------------------

Check https://citellus.org for more details and information



.. _Citellus-www: http://htmlpreview.github.io/?https://github.com/citellusorg/citellus/blob/master/doc/sampleweb/citellus.html
.. _Changelog.md: Changelog.md
.. _citellusclient/plugins/: citellusclient/plugins/
.. _Citellus README: README.citellus.md
.. _Magui README: README.magui.md
.. _asciicast: https://asciinema.org/a/169814
.. _devconf.cz 2018!!: https://devconfcz2018.sched.com/event/DJXG/detect-pitfalls-of-osp-deployments-with-citellus
