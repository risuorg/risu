#!/usr/bin/env python
# encoding: utf-8
import os
import sys
sys.path.append(os.path.abspath(os.path.dirname(__file__) + '/' + '../'))

from maguiclient.magui import main

if __name__ == "__main__":
    sys.exit(main())
