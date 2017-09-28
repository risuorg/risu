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
```sh
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


## Common Functions
We provide helper script `common-functions.sh` to help define
location of various files. To use this script you can source it at the top:

```sh
# Load common functions
[ -f "${CITELLUS_BASE}/common-functions.sh" ] && . "${CITELLUS_BASE}/common-functions.sh"
```

### List of implemented functions
- `$systemctl_list_units_file` -- if tests are running against a filesystem
  snapshot of some sort. This variable can be used to easier identify the
  systemctl list units file.

- `$journalctl_file` -- if tests are running against a filesystem
  snapshot of some sort. This variable can be used to easier identify the
  systemctl list units file.

- `is_active $service` -- reports if service is active either based on live or snapshoot
    - Example:
        ~~~sh
        if is_active ntpd; then echo "NTP Running";fi
        ~~~

- `is_required_file $file` -- continues if file exists or exits `$RC_SKIPPED` if doesn't
    - Example:
        ~~~sh
        is_required_file "${CITELLUS_ROOT}/var/log/messages"
        ~~~


- `is_required_rpm $rpm` -- continues if rpm is installed or exits with `$RC_SKIPPED` if required rpm is missing
    - Example:
        ~~~sh
        is_required_rpm sos
        ~~~

- `discover_osp_version $openstack-nova-common-version_package` -- echos osp version based on `openstack-nova-common version`
    - Example:
        ~~~sh
        if [[ "$(discover_osp_version)" -eq "10" ]]; then echo "We're Newton";fi
        ~~~

- `name_osp_version $openstack-nova-common-version_package` -- echos osp version 'codename' based on `openstack-nova-common version`
    - Example:
        ~~~sh
        if [[ "$(name_osp_version)" -eq "pike" ]]; then echo "We're Pike!";fi
        ~~~

- `is_rpm $rpm` -- returns rpm name as installed on the system
    - Example:
        ~~~sh
        # is_rpm sos
        sos-3.2-15.el7.noarch
        ~~~

- `is_process $process` -- returns if process exists on the system
    - Example:
        ~~~sh
        if is_process ntpd; then echo "NTP Running!";fi
        ~~~
