## Writing checks

Citellus tests should conform to the following standards:

- The test script must be executable. Citellus will ignore tests for
  which it does not have execute permission (and report CI errors if there's a file which has not +x set in the plugins folder)

- Test should include a line starting with `# description: `, `# long_name`, `# priority` and optional `# bugzilla` followed with a one line comment which describes plugin information, for example:
    ~~~sh
    # description: This plugins does check answer for Universe and everything
    # long_name: This is a tests for emulating Deep Tought answers
    # priority: 500
    # bugzilla: https://bugzilla.redhat.com/show_bug.cgi?id=746698
    ~~~

- The test should return one of the following error codes to indicate
  the test result:

    - $RC_OKAY -- success
    - $RC_FAILED -- failure
    - $RC_SKIPPED -- skipped

- Plugin output should we written to STDERR, for example with:

    ~~~
    echo "This test has failed" >&2
    ~~~

    - Additionally strings that would be interesting to 'translate', should be preceded by $ like:

        ~~~
        echo $"This test has failed" >&2
        ~~~
    - In the same way that for python scripts using i18n you'll be using `_("string")`
    - This will allow `extractpot.sh` to use bash to dump strings in bash scripts that could be later translated with `poedit`.

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

- `iniparser` -- parses ini file and returns value in lowercase
    - Example:
        ~~~sh
        if [[ "$(iniparser $config_file DEFAULT debug)" == "true" ]]; then
            echo "debug enabled in $config_file"
        fi
        ~~~

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


- `is_process $process` -- returns if process exists on the system
    - Example:
        ~~~sh
        if is_process ntpd; then echo "NTP Running!";fi
        ~~~

- `is_lineinfile $pattern $files` -- returns if pattern match is found in file
    - Example:
        ~~~sh
        if is_lineinfile "^debug[ \t]*=[ \t]*true" "$config_file"; then echo "Debug enabled."; fi
        ~~~

- `is_required_containerized` -- continues if environment is containerized works only against OSP12 and later
    - Example:
        ~~~sh
        if is_required_containerized; then
            echo "Environment is containerized"
        fi
        ~~~

- `is_containerized` -- returns true or false if environment is containerized works only against OSP12 and later
    - Example:
        ~~~sh
        if is_containerized; then
            echo "Environment is containerized"
        else
            echo "Environment is NOT containerized"
        fi
        ~~~

- `docker_runit` -- execute the command inside docker works only with docker
    - Example:
        ~~~sh
        # docker exec -i $(docker ps | grep rabbitmq-bundle | cut -d" " -f1) sh -c "rabbitmqctl report"
        docker_runit "rabbitmq-bundle" "rabbitmqctl report" | grep partitions
        ~~~

- `discover_rhrelease` -- find RH Release number based on /etc/redhat-release code name
    - Example:
        ~~~sh
        if [[ $(discover_rhrelease) -eq "7" ]] ; then
            echo "RHEL 7 detected"
        else
            echo "RHEL 7 not detected"
        fi
        ~~~
    - NOTE: It might return '0', so it's convenient in your scripts to run something like:
        ~~~sh
        [[ "${RELEASE}" -eq '0' ]] && echo "RH release undefined" >&2 && exit ${RC_SKIPPED}
        ~~~
        To early leave the script

- `is_pkg $pkg` -- returns package version if installed on system (RHEL/Centos/Fedora | Debian)
    - Example:
        ~~~sh
        # is_pkg systat
        sos-3.2-15.el7.noarch
        ~~~

- `is_required_pkg $pkg` -- continues if package is installed or exits with `$RC_SKIPPED` if required package is missing
    - Example:
        ~~~sh
        is_required_pkg sysstat
        ~~~

- `is_pkg_over $pkg` -- Checks if provided package is over specific release
    - Example:
        ~~~sh
        if is_pkg_over dracut dracut-033-502; then  ## Note, version string is DISTRO dependent
            echo "dracut is not affected by spectre"
        else
            echo "update dracut to get the fix for spectre vulnerability"
        fi
        ~~~

- `is_required_pkg_over $pkg` -- Checks if provided PKG is over specific release or exit as FAILED
    - Example:
        ~~~sh
        is_required_pkg_over dracut dracut-033-502
        ~~~


- `is_rpm $rpm` -- returns rpm name as installed on the system
    - Example:
        ~~~sh
        # is_rpm sos
        sos-3.2-15.el7.noarch
        ~~~

- `is_dpkg $dpkg` -- returns dpkg version as installed on the system
    - Example:
        ~~~sh
        # is_dpkg libc6
        2.12.1-0ubuntu10.2
        ~~~

- `is_required_rpm $rpm` -- Fallsback to `is_required_pkg $package` after forcing `rpm` distro check.
- `is_rpm_over` -- Fallsback to `is_pkg_over $package` after forcing `rpm` distro check.
- `is_required_rpm_over` -- Fallsback to `is_required_pkg_over $package` after forcing `rpm` distro check.

- `is_required_dpkg $dpkg` -- Fallsback to `is_required_pkg $package` after forcing `dpkg` distro check.
- `is_dpkg_over` -- Fallsback to `is_pkg_over $package` after forcing `dpkg` distro check.
- `is_required_dpkg_over` -- Fallsback to `is_required_pkg_over $package` after forcing `dpkg` distro check.

- `are_dates_diff_over` -- Checks if two dates are over X days in diff
    - Example:
        ~~~sh
        are_dates_diff_over 5 "2017-12-01 14:40" "2017-12-31 14:45"
        ~~~

- `is_filemode $mode $file` -- Checks file mode on disk to be XXXX, for example 0755
- `is_required_filemode $mode $file` -- Fallsback to is_filemode requiring file and mode to exist and being equal
