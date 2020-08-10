#!/usr/bin/env python
# -*- coding: utf-8 -*-
# Copyright (C) 2017, 2018, 2019, 2020 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

import os
import re
import setuptools
import subprocess
import time

# In python < 2.7.4, a lazy loading of package `pbr` will break
# setuptools if some other modules registered functions in `atexit`.
# solution from: http://bugs.python.org/issue15881#msg170215

try:
    import multiprocessing  # noqa
except ImportError:
    pass

command = "git tag|sort -V|grep -v ^[a-Z]|grep -v 2017|tail -1"
proc = subprocess.Popen([command], stdout=subprocess.PIPE, shell=True)
(out, err) = proc.communicate()

version = out.strip().decode("utf-8")

try:
    travis = os.environ["TRAVIS_JOB_ID"]
except:
    travis = None

strings = time.strftime("%Y,%m,%d,%H,%M,%S")
t = strings.split(",")
numbers = [str(x) for x in t]

if travis:
    os.environ["PBR_VERSION"] = "%s.%s.%s" % (version, travis, "".join(numbers))
else:
    os.environ["PBR_VERSION"] = "%s.%s.%s" % (version, 0, "".join(numbers))

setuptools.setup(setup_requires=["pbr>=2.0.0"], pbr=True)
