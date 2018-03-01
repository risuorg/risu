#!/usr/bin/env python
# encoding: utf-8

import setuptools
import os
import re

# In python < 2.7.4, a lazy loading of package `pbr` will break
# setuptools if some other modules registered functions in `atexit`.
# solution from: http://bugs.python.org/issue15881#msg170215

try:
    import multiprocessing  # noqa
except ImportError:
    pass

filename = 'setup.cfg'
regexp = '\Aversion.*([0-9]+)'

with open(filename, 'r') as f:
    for line in f:
        if re.match(regexp, line):
            # Return earlier if match found
            break

version = line.split("=")[1].strip()
try:
    travis = os.environ['TRAVIS_JOB_ID']
except:
    travis = None

if travis:
    os.environ['PBR_VERSION'] = "%s.%s" % (version, travis)

setuptools.setup(setup_requires=['pbr>=2.0.0'], pbr=True)
