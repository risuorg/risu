# Deprecation Warning

The files has been moved to `risu` main directory [https://github.com/risuorg/risu/](https://github.com/risuorg/risu/)

We created risu to be importable module and made a script that imports it.

- Original `risu/risu.py` has been moved under `risuclient/shell.py` and script `risu.py` in the main directory now imports `risuclient.shell`
- The same with `risu/magui.py` has been moved as well under `maguiclient/magui.py` and script `magui.py` in the main directory just imports `maguiclient.magui`

The right way to execute this application is to use `risu.py` or `magui.py` from the main directory, these files only work as a bridge between the new and old folder structure.

Reason for these scripts is because we had issues with imports from different directories.
