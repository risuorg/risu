.. image:: https://img.shields.io/github/license/risuorg/risu.svg :alt: LICENSE
.. image:: https://github.com/risuorg/risu/workflows/Python%20Unit%20Testing/badge.svg :alt: Actions status
.. image:: https://codecov.io/gh/risuorg/risu/branch/master/graph/badge.svg :target: https://codecov.io/gh/risuorg/risu
.. image:: https://img.shields.io/github/release/risuorg/risu.svg :alt:  Releases
.. image:: https://badge.fury.io/py/risu.svg :alt:  Pypi version

Introduction
============

Risu is a framework to help with system configuration validation on
either live system or any sort of snapshot of the filesystem.

Via execution of 'plugins' it reports status on each one execution
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
   -  Check our sample at: `Risu-www`_

-  Ansible playbook support.
-  Save / restore default settings

Check latest changes on `Changelog.md`_

Check for plugins listing on `risuclient/plugins/`_

Framework contains additional readmes for the tools included:

-  `Risu README`_
-  `Magui README`_

Installation
------------

Check ``README`` above for detailed instructions outside os simple ones:
- Just clone the git repository and execute it from there 'or' - use
'pipsi' or create a python virtual env to install package 'risu'

-  Give it a try running as 'root' on your system with:
   ``./risu.py -l`` so it will show ``live execution`` and only
   ``Failed`` tests.

How does it looks like?
-----------------------

Check how does it look in an execution at: `asciicast`_


Additional resources
--------------------

Check https://risuorg.github.io for more details and information



.. _Risu-www: https://risuorg.github.io/risu.html
.. _Changelog.md: Changelog.md
.. _risuclient/plugins/: risuclient/plugins/
.. _Risu README: README.risu.md
.. _Magui README: README.magui.md
.. _asciicast: https://asciinema.org/a/169814
.. _devconf.cz 2018!!: https://devconfcz2018.sched.com/event/DJXG/detect-pitfalls-of-osp-deployments-with-risu
