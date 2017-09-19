## Writing checks

Citellus tests should conform to the following standards:

- The test script must be executable. Citellus will ignore tests for
  which it does not have execute permission.

- The test should return one of the following error codes to indicate
  the test result:

    - $RC_OKAY -- success
    - $RC_FAILED -- failure
    - $RC_SKIPPED -- skipped

A test may make use of the following standard environment variables:

- `$CITELLUS_ROOT` -- tests that parse files should locate them
  relative to this directory.  For example, if your script needs to
  examine `/etc/sysctl.conf`, it might have something like:
```
if grep -q '^net.ipv4.ip_forward = 1' "${CITELLUS_ROOT}/etc/sysctl.conf"; then
  ...
fi
```
- `$CITELLUS_LIVE` -- if `0`, tests are running against a filesystem
  snapshot of some sort.  Tests should not attempt to use commands
  that interrogate the system on which it is running.  If this
  variable is `1`, the tests are running on a live system.

- `$CITELLUS_BASE` -- this is location of the citellus folder.

- `$PLUGIN_BASEDIR` -- this contains the folder of the plugin that is being executed.
  The `$PLUGIN_BASEDIR` can be used to source files within the plugin folder.

We provide helper script `common-functions.sh` to help define
location of various files. To use this script you can source it at the top:

```
# Load common functions
[ -f "${CITELLUS_BASE}/common-functions.sh" ] && . "${CITELLUS_BASE}/common-functions.sh"
```

- `$systemctl_list_units_file` -- if tests are running against a filesystem
  snapshot of some sort. This variable can be used to easier identify the
  systemctl list units file.

- `$journalctl_file` -- if tests are running against a filesystem
  snapshot of some sort. This variable can be used to easier identify the
  systemctl list units file.
