#!/usr/bin/env python
# Copyright (C) 2018-2020, 2023 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>
import os
import sys

sys.path.append(os.path.abspath(os.path.dirname(__file__) + "/" + "../"))

from maguiclient.magui import main

if __name__ == "__main__":
    sys.exit(main())
