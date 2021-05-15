## Introduction

Risu is a program that should help with system configuration validation on either live system or any sort of snapshot of the filesystem.

Via execution of 'plugins' it reports status on each one execution against the system that gives you an idea on health status, actual problems or problems that will reveal themselves if no preventive action is taken.

Please if you have any idea on any improvements please do not hesitate to open an issue.

## Highlights

- Plugins written in your language of choice.
- Allows to dump output to json file to be processed by other tools.
  - Allow to visualize html from json output.
  - Check our sample at: [Risu-www](https://risuorg.github.io/risu.html)
- Ansible playbook support.
- Save / restore default settings

Check latest changes on [changelog.md](changelog.md)

Check for plugins listing on [risuclient/plugins/](risuclient/plugins/)

## Installation

- Just clone the git repository and execute it from there 'or'
- use 'pipsi' or create a python virtual env to install package 'risu'
  ```sh
  # pipsi install risu
  Already using interpreter /usr/bin/python3
  Using base prefix '/usr'
  New python executable in /home/iranzo/.local/venvs/risu/bin/python3
  Also creating executable in /home/iranzo/.local/venvs/risu/bin/python
  Installing setuptools, pip, wheel...done.
  Collecting risu
  Installing collected packages: risu
  Successfully installed risu-0.1.0.dev1072
    Linked script /home/iranzo/.local/bin/risu.py
    Linked script /home/iranzo/.local/bin/magui.py
  Done.
  ```
  - Pipsi will take care of installing a virtual environment and link to binary folder so you can call risu.py or magui.py directly
  - Remember that pypi package might not contain all the latests plugins features as the github repo one.
- Container:
  - Use our automatically built container in docker hub:
    - `docker run --user=$(id -u) --rm -v $PATHTOSOSREPORT:/data:Z risu/risu:latest /data`
  - or build your own using the included `Dockerfile` in the git checkout.
    - `docker build . -f Dockerfile.centos7-atomic -t risu:latest` # (from git checkout, then note image id)
    - `docker run --user=$(id -u) --rm -v $PATHTOSOSREPORT:/data:Z risu:latest /data`
  - Notes about using docker:
    - Docker passes as volume the path specified under /data so we do use that parameter with risu for running the tests.
    - The default user id within the container is 10001 and the commands or sosreport permissions doesn't allow that user to gather all the information, so the container is required to run as the current user.

## Usage help

We are developing framework in python, the bash framework has been deprecated. Python framework is the only supported framework.

```
usage: risu.py [arguments] [-h] [-l] [--list-plugins] [--list-extensions] [--list-categories] [--description] [--list-hooks] [--dump-overrides] [--output FILENAME] [--web] [--run] [--find] [--blame]
                               [--lang LANG] [-v] [-d {INFO,DEBUG,WARNING,ERROR,CRITICAL}] [-q] [--progress PROGRESS]
                               [--progress-colour {black,red,green,orange,blue,magenta,purple,cyan,lightgrey,darkgrey,lightred,lightgreen,yellow,lightblue,pink,lightcyan}] [--progress-start PROGRESS_START]
                               [--progress-end PROGRESS_END] [-i SUBSTRING] [-x SUBSTRING] [-p [0-1000]] [-hf SUBSTRING] [--anon] [--dump-config] [--no-config] [--call-home serveruri]
                               [--extraplugintree extraplugintree]
                               [sosreport]

Risu allows to analyze a directory against common set of tests, useful for finding common configuration errors

positional arguments:
  sosreport

optional arguments:
  -h, --help            show this help message and exit
  -l, --live            Work on a live system instead of a snapshot
  --list-plugins        Print a list of discovered plugins and exit
  --list-extensions     Print a list of discovered extensions and exit
  --list-categories     With list-plugins, also print a list and count of discovered plugin categories
  --description         With list-plugins, also outputs plugin description
  --list-hooks          Print a list of discovered hooks and exit
  --dump-overrides      Dumps full options of overrides.json to current directory
  --output FILENAME, -o FILENAME
                        Write results to JSON file FILENAME
  --web                 Write results to JSON file risu.json and copy html interface in path defined in --output
  --run, -r             Force run of risu instead of reading existing 'risu.json'
  --find                Use provided path at starting point for finding risu.json and print them based on filters defined

Output and logging options:
  --blame               Report time spent on each plugin
  --lang LANG           Define locale to use
  -v, --verbose         Increase verbosity of output (may be specified more than once)
  -d {INFO,DEBUG,WARNING,ERROR,CRITICAL}, --loglevel {INFO,DEBUG,WARNING,ERROR,CRITICAL}
                        Set log level
  -q, --quiet           Enable quiet mode
  --progress PROGRESS   Character to use as progress meter
  --progress-colour {black,red,green,orange,blue,magenta,purple,cyan,lightgrey,darkgrey,lightred,lightgreen,yellow,lightblue,pink,lightcyan}
                        Colour to use for progress meter
  --progress-start PROGRESS_START
                        String to use as progress start
  --progress-end PROGRESS_END
                        String to use as progress end

Filtering options:
  -i SUBSTRING, --include SUBSTRING
                        Only include plugins that contain substring
  -x SUBSTRING, --exclude SUBSTRING
                        Exclude plugins that contain substring
  -p [0-1000], --prio [0-1000]
                        Only include plugins are equal or above specified prio
  -hf SUBSTRING, --hfilter SUBSTRING
                        Only include hooks that contain substring
  --anon                Anonymize output

Config options:
  --dump-config         Dump config to console to be saved into file
  --no-config           Do not read configuration from file ${INSTALLDIR}/risuclient/risu.conf or ~/.risu.conf
  --call-home serveruri
                        Server URI to HTTP-post upload generated risu.json for metrics
  --extraplugintree extraplugintree
                        Adds extra plugin tree structure for plugins

```

Check how does it look in an execution at:
[![asciicast](https://asciinema.org/a/169814.png)](https://asciinema.org/a/169814)

## Plugins and their descriptions

This is new feature of risu that will show you available scripts and their description.

```
./risu.py --list-plugins --description
{'backend': 'core', 'description': 'This plugin checks if Apache reaches its MaxRequestWorkers', 'plugin': '${INSTALLDIR}/risuclient/plugins/core/bugzilla/httpd/1406417.sh'}
{'backend': 'core', 'description': 'Checks missconfigured host in nova vs hostname', 'plugin': '${INSTALLDIR}/risuclient/plugins/core/bugzilla/openstack/ceilometer/1483456.sh'}
{'backend': 'core', 'description': 'Checks for outdated ceph packages', 'plugin': '${INSTALLDIR}/risuclient/plugins/core/bugzilla/openstack/ceph/1358697.sh'}
{'backend': 'core', 'description': 'Checks httpd WSGIApplication defined to avoid wrong redirection', 'plugin': '${INSTALLDIR}/risuclient/plugins/core/bugzilla/openstack/httpd/1478042.sh'}
{'backend': 'core', 'description': 'Checks for keystone transaction errors on cleanup', 'plugin': '${INSTALLDIR}/risuclient/plugins/core/bugzilla/openstack/keystone/1473713.sh'}
{'backend': 'core', 'description': 'Checks for keystone LDAP domain template problem', 'plugin': '${INSTALLDIR}/risuclient/plugins/core/bugzilla/openstack/keystone/templates/1519057.sh'}
{'backend': 'core', 'description': 'Checks for wrong auth_url configuration in metadata_agent.ini', 'plugin': '${INSTALLDIR}/risuclient/plugins/core/bugzilla/openstack/neutron/1340001.sh'}
{'backend': 'core', 'description': 'Checks python-ryu tracebacks', 'plugin': '${INSTALLDIR}/risuclient/plugins/core/bugzilla/openstack/neutron/1450223.sh'}
```

## Doing a live check example

This is an example of execution of Risu using all openstack and pacemaker tests collections.

```
./risu.py -q -l -i pacemaker -i openstack
INFO:risu:using default plugin path
# /root/risu/risuclient/plugins/core/bugzilla/openstack/ceilometer_bug_1483456.sh: failed
    https://bugzilla.redhat.com/show_bug.cgi?id=1483456
# /root/risu/risuclient/plugins/core/bugzilla/openstack/ceph_bug_1358697.sh: failed
    outdated ceph packages: https://bugzilla.redhat.com/show_bug.cgi?id=1358697
# /root/risu/risuclient/plugins/core/bugzilla/openstack/httpd_bug_1478042.sh: skipped
# /root/risu/risuclient/plugins/core/bugzilla/openstack/keystone_bug_1473713.sh: okay
# /root/risu/risuclient/plugins/core/bugzilla/openstack/neutron_bug_1450223.sh: skipped
# /root/risu/risuclient/plugins/core/bugzilla/openstack/neutron_bug_1474092.sh: okay
# /root/risu/risuclient/plugins/core/bugzilla/openstack/neutron_bug_1489066.sh: okay
# /root/risu/risuclient/plugins/core/bugzilla/openstack/nova_bug_1474092.sh: okay
# /root/risu/risuclient/plugins/core/bugzilla/openstack/swift_bug_1500607.sh: failed
    swift expirer https://bugzilla.redhat.com/show_bug.cgi?id=1500607
# /root/risu/risuclient/plugins/core/launchpad/openstack/keystone_bug_1649616.sh: okay
# /root/risu/risuclient/plugins/core/openstack/ceilometer/expiration.sh: failed
    ceilometer.conf setting must be updated:
    alarm_history_time_to_live = -1
    ceilometer.conf setting must be updated:
    event_time_to_live = -1
    ceilometer.conf setting must be updated:
    metering_time_to_live = -1
```

## Doing a fs snapshot check example

This is an example of execution of Risu using `pacemaker` and `openstack` filter against fs snapshot.

```
./risu.py -q -i pacemaker -i openstack sosreport-undercloud-0.redhat.local-20171117212710/
INFO:risu:using default plugin path
# /root/risu/risuclient/plugins/core/bugzilla/openstack/ceilometer_bug_1483456.sh: failed
    https://bugzilla.redhat.com/show_bug.cgi?id=1483456
# /root/risu/risuclient/plugins/core/bugzilla/openstack/ceph_bug_1358697.sh: failed
    outdated ceph packages: https://bugzilla.redhat.com/show_bug.cgi?id=1358697
# /root/risu/risuclient/plugins/core/bugzilla/openstack/httpd_bug_1478042.sh: skipped
# /root/risu/risuclient/plugins/core/bugzilla/openstack/keystone_bug_1473713.sh: okay
# /root/risu/risuclient/plugins/core/bugzilla/openstack/neutron_bug_1450223.sh: skipped
# /root/risu/risuclient/plugins/core/bugzilla/openstack/neutron_bug_1474092.sh: okay
# /root/risu/risuclient/plugins/core/bugzilla/openstack/neutron_bug_1489066.sh: okay
# /root/risu/risuclient/plugins/core/bugzilla/openstack/nova_bug_1474092.sh: okay
# /root/risu/risuclient/plugins/core/bugzilla/openstack/swift_bug_1500607.sh: failed
    swift expirer https://bugzilla.redhat.com/show_bug.cgi?id=1500607
# /root/risu/risuclient/plugins/core/launchpad/openstack/keystone_bug_1649616.sh: okay
# /root/risu/risuclient/plugins/core/openstack/ceilometer/expiration.sh: failed
    ceilometer.conf setting must be updated:
    alarm_history_time_to_live = -1
    ceilometer.conf setting must be updated:
    event_time_to_live = -1
    ceilometer.conf setting must be updated:
    metering_time_to_live = -1
```

## HTML Interface

- Create by using `--output $FOLDER` and `--web`, open the generated `risu.html`.

<img src="images/www.png" height="40%" border=0>

- Risu-web now supports the parsing of magui.json.

- It's possible to tell the risu.html which json to parse by adding json=<jsonfile> as a query string:

```
http://host/risu.html?json=magui.json
```

## Ansible playbooks

Risu can also run Ansible playbooks via extension

The are some additional conventions that are detailed in [ansible-playbooks.md](development/ansible-playbooks.md) that determine how to code them to be executed in live or snapshoot mode.

Commands have been extended to allow `--list-plugins` to list them and include /exclude filters to work with them.

All of them must end in `.yml`.

```
found #1 extensions / found #0 tests at default path
mode: fs snapshot .
# Running extension ansible-playbook
# ${INSTALLDIR}/risu/playbooks/system/clock-ntpstat.yml: skipped
    Skipped for incompatible operating mode
```

vs

```
found #2 extensions with #2 plugins
mode: live
# ${INSTALLDIR}/risuclient/plugins/ansible/openstack/rabbitmq/ha-policies.yml: okay
# ${INSTALLDIR}/risuclient/plugins/ansible/system/clock-ntpstat.yml: failed
    {"changed": false, "cmd": "ntpstat", "msg": "[Errno 2] No such file or directory",

```
