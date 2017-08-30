# Writing Unit tests for plugins
Citellus uses unittesting for the main python wrappers (citellus.py and magui.py), but tests are mostly written in `bash` so no UT is performed.

As a workaround and to detect issues in your code you can:

- Test the code as part of functional testing (like we do for each test we develop)
- Consider creating unittests for it

# Creating the tests
Tests require two things:
- Script that setups a fake folder with relevant contents to either `pass`, `skipped` or `fail` a test
- The actual `unittest` that `tox` executes via `py.test`

For example, for bugzilla_httpd_bug_1406417 we create:

- `tests/plugins-unit-tests/setup/bugzilla/httpd_bug_1406417.sh`
- `tests/plugins-unit-tests/test_bugzilla_httpd_bug_1406417.py`

First file (in the `setup/` folder) does the proper setup of the fake root:

~~~bash
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
~~~

You'll need to adapt above code or use it as template for creating your own `setup` script.

Once done, the actual `unittest` should be checked, for example (note that test is named test_$PLUGINNAME):

~~~py
# import required libraries
import os
import subprocess
from unittest import TestCase
import tempfile
import shutil

from citellus import citellus

# our name
NAME = 'httpd_bug_1406417'
testplugins = os.path.join(citellus.citellusdir, 'testplugins')
plugins = os.path.join(citellus.citellusdir, 'plugins')
folder = os.path.join(os.path.abspath(os.path.dirname(__file__)), 'setup')
uttest = citellus.findplugins(folders=[folder], include=[NAME])[0]
us = os.path.basename(uttest)
citplugs = citellus.findplugins(folders=[plugins], include=[us])

# Setup commands and expected return codes
rcs = {"pass": citellus.RC_OKAY,
       "fail": citellus.RC_FAILED,
       "skipped": citellus.RC_SKIPPED}

## Here we do start the tests, one for pass, one for fail and one for skipped

# This part of the code should be very similar for other tests as in the end, it's setting up the env with the prior script and then, executing plain citellus against it with the plugin filter set to our name so we only run one test against

class CitellusTest(TestCase):
    def test_bugzilla_httpd_bug_1406417_pass(self):
        # testtype will be 'pass', 'fail', 'skipped'
        testtype = 'pass'

        # We're iterating against the different UT tests defined in UT-tests folder
        tmpdir = tempfile.mkdtemp(prefix='citellus-tmp')

        # Setup test for 'pass'
        subprocess.call([uttest, uttest, testtype, tmpdir])

        # Run test against it
        res = citellus.docitellus(path=tmpdir, plugins=citplugs)

        # Get Return code
        rc = res[0]['result']['rc']

        # Remove tmp folder
        shutil.rmtree(tmpdir)

        # Check if it passed
        expected = rcs[testtype]
        assert rc == expected

    def test_bugzilla_httpd_bug_1406417_fail(self):
        # testtype will be 'pass', 'fail', 'skipped'
        testtype = 'fail'

        # We're iterating against the different UT tests defined in UT-tests folder
        tmpdir = tempfile.mkdtemp(prefix='citellus-tmp')

        # Setup test for 'fail'
        subprocess.call([uttest, uttest, testtype, tmpdir])

        # Run test against it
        res = citellus.docitellus(path=tmpdir, plugins=citplugs)

        # Get Return code
        rc = res[0]['result']['rc']

        # Remove tmp folder
        shutil.rmtree(tmpdir)

        # Check if it passed
        expected = rcs[testtype]
        assert rc == expected

    def test_bugzilla_httpd_bug_1406417_skip(self):
        # testtype will be 'pass', 'fail', 'skipped'
        testtype = 'skipped'

        # We're iterating against the different UT tests defined in UT-tests folder
        tmpdir = tempfile.mkdtemp(prefix='citellus-tmp')

        # Setup test for 'skipped'
        subprocess.call([uttest, uttest, testtype, tmpdir])

        # Run test against it
        res = citellus.docitellus(path=tmpdir, plugins=citplugs)

        # Get Return code
        rc = res[0]['result']['rc']

        # Remove tmp folder
        shutil.rmtree(tmpdir)

        # Check if it passed
        expected = rcs[testtype]
        assert rc == expected
~~~

Let us know if you face any issue while creating them.
