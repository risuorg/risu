#!/usr/bin/env python
# encoding: utf-8
# Copyright (C) 2017, 2018 Pablo Iranzo Gómez <Pablo.Iranzo@redhat.com>
# Copyright (C) 2017 Robin Černín <rcernin@redhat.com>

import os
import sys


def main(args=None):
    """The main routine."""
    if args is None:
        args = " ".join(sys.argv[1:])
    citellusdir = "/".join(os.path.abspath(os.path.dirname(__file__)).split("/")[:-1]) + '/magui.py'
    os.system(citellusdir + " " + args)


if __name__ == "__main__":
    main()

