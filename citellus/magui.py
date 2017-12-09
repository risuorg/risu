#!/usr/bin/env python
# encoding: utf-8
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
