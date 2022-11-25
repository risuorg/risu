#!/usr/bin/env python
# -*- coding: utf-8 -*-
# Copyright (C) 2017 Robin Černín <cerninr@gmail.com>
# Copyright (C) 2017 Lars Kellogg-Stedman <lars@redhat.com>
# Copyright (C) 2017-2022 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

import os
import sys


def main(args=None):
    """The main routine."""
    if args is None:
        args = " ".join(sys.argv[1:])
    risudir = (
        "/".join(os.path.abspath(os.path.dirname(__file__)).split("/")[:-1])
        + "/risu.py"
    )
    os.system(risudir + " " + args)


if __name__ == "__main__":
    main()
