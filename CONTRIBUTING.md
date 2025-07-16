**Table of contents**

<!-- TOC depthFrom:1 insertAnchor:false orderedList:false -->

- [How to file a bug report](#how-to-file-a-bug-report)
- [How to contribute code](#how-to-contribute-code)
- [Plugin Priority System](#plugin-priority-system)
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

## Plugin Priority System

Plugin priorities are assigned based on system stability and operational continuity impact. **999 is the maximum criticality** (system can break at any moment) and **1 is the lowest priority** (informational only).

### Priority Categories

| Priority Range | Category               | Impact Level                   | Description                                                 | Examples                                                                |
| -------------- | ---------------------- | ------------------------------ | ----------------------------------------------------------- | ----------------------------------------------------------------------- |
| **900-999**    | Maximum Criticality    | System can break at any moment | Critical system components that can cause immediate failure | Filesystem corruption (950), etcd health (980), API server health (970) |
| **800-899**    | High Criticality       | System services at risk        | Core system services and infrastructure                     | Network issues (870), systemd problems (890), node health (880)         |
| **600-799**    | Medium Criticality     | Applications & Services        | Platform services and applications                          | OpenStack (750), OpenShift (740), databases (700)                       |
| **400-599**    | Medium-Low Criticality | Middleware & Support           | Supporting services and middleware                          | Web servers (580), load balancers, caching                              |
| **200-399**    | Low Criticality        | Monitoring & Logging           | Observability and monitoring systems                        | Monitoring (350), logging (330), performance (280)                      |
| **100-199**    | Very Low Criticality   | Informational                  | Informational and compliance checks                         | Informative plugins (150), compliance (130)                             |
| **1-99**       | Lowest Priority        | Metadata & Development         | Metadata collection and development tools                   | Metadata (70), development tools (50)                                   |

### Priority Assignment Guidelines

When creating or updating plugins, assign priorities based on:

1. **System Stability Impact**: How quickly could this issue cause system failure?
2. **Operational Continuity**: How much would this affect ongoing operations?
3. **Recovery Difficulty**: How hard would it be to recover from this issue?
4. **Blast Radius**: How many systems/users would be affected?

### Examples by Priority

- **980**: etcd cluster health - etcd failure breaks the entire cluster
- **950**: Filesystem corruption - can cause immediate data loss
- **940**: Disk space full - system can become unresponsive
- **880**: Node health issues - affects workload scheduling
- **870**: Network connectivity problems - affects all communications
- **750**: OpenStack service issues - affects cloud operations
- **400**: General system configuration issues
- **350**: Monitoring system problems - affects observability
- **150**: Informational system inventory
- **70**: Metadata collection - purely informational

## How to write tests

Please refer to the
[templates](https://github.com/risuorg/risu/tree/master/doc/templates)
folder for examples.

Specially remember about the headers:

```
# long_name: plug long name for webui
# description: plug description
# bugzilla: bz url
# priority: 1-999 (999=max criticality, 1=lowest priority)
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
