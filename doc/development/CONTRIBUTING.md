**Table of contents**

<!-- TOC depthFrom:1 insertAnchor:false orderedList:false -->

- [How to file a bug report](#how-to-file-a-bug-report)
- [How to contribute code](#how-to-contribute-code)
- [How to write tests](#how-to-write-tests)
- [How to debug your test](#how-to-debug-your-test)

<!-- /TOC -->

## How to file a bug report

If you have any suggestions for improvements please do not hesitate to
open an [issue](https://github.com/risuorg/risu/issues/new).

## How to contribute code

We encourage you to contribute new plugins. Use Pull Requests to provide your contributions to the repo.

[gerrithub]: https://gerrithub.io/

1.  Clone the risu repository:
    `git clone https://github.com/risuorg/risu`
2.  Install pre-commit (from pipsi for example) and prepare the hook:
    `pre-commit install`
3.  Check out a branch in which to make your changes:
    `git checkout -b "your-new-branch"`
4.  Edit your files and validate with tox:
    `tox # this will check the changes for some errors`
    NOTE: tox will run python 2.7, pep8 and python 3.5 tests, if your environment lacks for example python 3.5, do execute tox -l to see the available tests and skip that one, for example:

    ```sh
    tox -e pep8
    tox -e py27  # We're skipping tox -e py35 which is also invoked by default when tox is executed without arguments.
    ```

    In this way, errors that might be relevant to the test environment can be skipped. For example this one reported at issue tracker as [104](https://github.com/risuorg/risu/issues/104))

5.  Update your local repository:
    `git add $modified_files git commit`

        For the message, please use a short line with the fix and the subject like `[plugins][openstack][nova] Check nova configuration XXX`

        If the commit fixes a github open issue, also use `Closes #$ISSUEID` so github automatically closes it once merged referencing the commit.

6.  Submit your changes for review:

    `git push`

7.  Then, use repository Pull-Request method to request the change to be incorporated/reviewed

        git-review

Then wait for your changes to be reviewed. It is common for reviewers
to request changes; when this happens:

1.  Edit your files and revalidate with tox:

        tox # this will check the new changes for some errors

2.  Update your existing commit. Do not create a new commit! We want to get each new PR into one commit.

        git add $modified_files
        git commit --amend

3.  Resubmit the change:

        git push --force

4) Once the new plugin has been submitted you'll see some GitHub actions feedback (similars to the ones that you run with `tox`)

## How to write tests

Please refer to the
[templates](https://github.com/risuorg/risu/tree/master/doc/templates)
folder for examples.

Specially remember about the headers:

```
# long_name: plug long name for webui
# description: plug description
# bugzilla: bz url
# priority: 0<>1000 for likelihood to break your environment if this test reports fail
# kb: url-to-kbase
```

That are used by Risu to fill json metadata.

If you want to contribute also Unittests for your plugins, check [TESTING.md](TESTING.md)

For contributing translations check [i18n.md](i18n.md)

## How to debug your test

We've included a file named `env-for.debug.sh` in the root folder of Risu repo that allows to be sourced and later execute your script.

This environment file will define the standard variables Risu does use like:

- RC_OKAY
- RC_FAILED
- RC_SKIPPED
- RC_INFO
- TEXTDOMAIN
- TEXTOMAINDIR
- RISU_BASE
- RISU_LIVE
- RISU_ROOT

And will preload the common-functions

The way to use it is:

```sh
. ~/risu/env-for-debug.sh
```

Then you can debug your script with:

```
sh -x /path/to/your/plugin.sh
```

Or test individual functions output like:

```
is_rpm qemu-kvm-rhev
```

Please, do note that as some functions do 'exit' or 'return' for example executing `is_rpm_over` will exit the active shell, so beware!!
