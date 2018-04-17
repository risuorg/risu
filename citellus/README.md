# Deprecation Warning

The files has been moved to `citellus` main directory [https://github.com/citellusorg/citellus/](https://github.com/citellusorg/citellus/)

We created citellus to be importable module and made a script that imports it.

- Original `citellus/citellus.py` has been moved under `citellusclient/shell.py` and script `citelus.py` in the main directory now imports `citellusclient.shell`
- The same with `citellus/magui.py` has been moved as well under `maguiclient/magui.py` and script `magui.py` in the main directory just imports `maguiclient.magui`

The right way to execute this application is to use `citellus.py` or `magui.py` from the main directory, these files only work as a bridge between the new and old folder structure.

Reason for these scripts is because we had issues with imports from different directories.
