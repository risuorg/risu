**Table of contents**

<!-- TOC depthfrom:1 insertanchor:false orderedlist:false -->

- [Writing Unit tests for plugins](#writing-unit-tests-for-plugins)
- [Creating the tests](#creating-the-tests)
- [Briefing](#briefing)

<!-- /TOC -->

## Writing Unit tests for plugins

Risu uses unit testing for the main python wrappers (`risu.py` and `magui.py`), but tests are mostly written in `bash` so no UT is performed.

As a workaround and to detect issues in your code you can:

- Test the code as part of functional testing (like we do for each test we develop)
- Consider creating unit tests for it

## Creating the tests

Tests require two things:

- Script that setups a fake folder with relevant contents to either `pass`, `skipped` or `fail` a test
- The actual `unittest` that `tox` executes via `py.test`

For example, for `bugzilla_httpd_bug_1406417` we create:

- `tests/plugins-unit-tests/setup/bugzilla/httpd_bug_1406417.sh`
- `tests/plugins-unit-tests/test_bugzilla_httpd_bug_1406417.py`

First file (in the `setup/` folder) does the proper setup of the fake root:

```sh
# The way we're executed, $1 is the script name, $2 is the mode and $3 is the folder
FOLDER=$3

case $2 in
    pass)
        # Create required files for test to pass
        mkdir -p $FOLDER
        # Touch the systemctl command we check
        mkdir -p "$FOLDER/var/log/httpd/"
        echo "" > "$FOLDER/var/log/httpd/error_log"
        ;;

    fail)
       # Create required files for test to fail
        mkdir -p $FOLDER
        # Touch the systemctl command we check
        mkdir -p "$FOLDER/var/log/httpd/"
        echo "MaxRequestWorkers" > "$FOLDER/var/log/httpd/error_log"
        ;;

    skip)
        # Do nothing, the folder will be empty and test should be skipped
        ;;
esac
```

You'll need to adapt above code or use it as template for creating your own `setup` script.

Once done, the actual `unittest` should be checked, for example (note that test is named `test\_\$PLUGINNAME`):

```py
import os
import subprocess
from unittest import TestCase
import tempfile
import shutil

from risu import risu

# To create your own test, update NAME with plugin name and copy this file to test_$NAME.py
NAME = 'httpd_bug_1406417'

testplugins = os.path.join(risu.risudir, 'plugins', 'test')
plugins = os.path.join(risu.risudir, 'plugins')
folder = os.path.join(os.path.abspath(os.path.dirname(__file__)), 'setup')
uttest = risu.findplugins(folders=[folder], include=[NAME])[0]
us = os.path.basename(uttest)
citplugs = risu.findplugins(folders=[plugins], include=[us])

# Setup commands and expected return codes
rcs = {"pass": risu.RC_OKAY,
       "fail": risu.RC_FAILED,
       "skipped": risu.RC_SKIPPED,
       "info": risu.RC_INFO}


def runtest(testtype='False'):
    # testtype will be 'pass', 'fail', 'skipped'

    # We're iterating against the different UT tests defined in UT-tests folder
    tmpdir = tempfile.mkdtemp(prefix='risu-tmp')

    # Setup test for 'testtype'
    subprocess.call([uttest, uttest, testtype, tmpdir])

    # Run test against it
    res = risu.dorisu(path=tmpdir, plugins=citplugs)

    # Get Return code
    rc = res[0]['result']['rc']

    # Remove tmp folder
    shutil.rmtree(tmpdir)

    # Check if it passed
    return rc


class RisuTest(TestCase):
    def test_pass(self):
        # testtype will be 'pass', 'fail', 'skipped'
        testtype = 'pass'
        assert runtest(testtype='fail') == rcs[testtype]

    def test_fail(self):
        # testtype will be 'pass', 'fail', 'skipped'
        testtype = 'fail'
        assert runtest(testtype=testtype) == rcs[testtype]

    def test_skip(self):
        # testtype will be 'pass', 'fail', 'skipped'
        testtype = 'skipped'
        assert runtest(testtype=testtype) == rcs[testtype]
```

## Briefing

For a new plugin and test you'll then require:

- `risu/risuclient/plugins/core/path-to-your-plugin/$NAME.sh`
- `tests/plugins-unit-tests/setup/bugzilla/$NAME.sh`
- `tests/plugins-unit-tests/test_$NAME.py`

You'll still have to code your plugin and the setup, and for the test, copy one of the provided `test\_.py` like `test_pacemaker_stonith_enabled.py`
and edit the 'NAME' variable inside the python file to match your plugin.

`tox` should now pick it up and report status.

Let us know if you face any issue while creating them.
