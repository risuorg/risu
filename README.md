[![License](https://img.shields.io/github/license/zerodayz/citellus.svg)](LICENSE)
[![Build Status](https://travis-ci.org/zerodayz/citellus.svg?branch=master)](https://travis-ci.org/zerodayz/citellus)
[![Coverage Status](https://coveralls.io/repos/github/zerodayz/citellus/badge.svg?branch=master)](https://coveralls.io/github/zerodayz/citellus?branch=master)
[![Release status](https://img.shields.io/github/release/zerodayz/citellus.svg)](https://github.com/zerodayz/citellus/releases)

<img src="doc/citellus.png" width="20%" border=0 align="right">

# Introduction

Citellus is a program that should help with system configuration validation on either live system or any sort of snapshot of the filesystem.

Please if you have any idea on any improvements please do not hesitate to open an issue.

Come to hear about us at [devconf.cz!!](https://devconfcz2018.sched.com/event/DJXG/detect-pitfalls-of-osp-deployments-with-citellus)

## Highlights
- Plugins in your language of choice.
- Allows to dump output to json file to be processed by other tools.
    - Allow to visualize html from json output.
- Ansible playbook support.
- Save / restore default settings

## Usage help
We are developing framework in python, the bash framework has been deprecated. Python framework is the only supported framework.

```
usage: citellus.py [arguments] [-h] [-l] [--list-plugins] [--list-extensions]
                               [--list-categories] [--description]
                               [--output FILENAME] [--web] [--blame] [--lang]
                               [--only-failed] [-v]
                               [-d {INFO,DEBUG,WARNING,ERROR,CRITICAL}] [-q]
                               [-i SUBSTRING] [-x SUBSTRING] [--dump-config]
                               [--no-config]
                               [sosreport]

Citellus allows to analyze a directory against common set of tests, useful for
finding common configuration errors

positional arguments:
  sosreport

optional arguments:
  -h, --help            show this help message and exit
  -l, --live            Work on a live system instead of a snapshot
  --list-plugins        Print a list of discovered plugins and exit
  --list-extensions     Print a list of discovered extensions and exit
  --list-categories     With list-plugins, also print a list and count of
                        discovered plugin categories
  --description         With list-plugins, also outputs plugin description
  --output FILENAME, -o FILENAME
                        Write results to JSON file FILENAME
  --web                 Write results to JSON file citellus.json and copy html
                        interface in path defined in --output

Output and logging options:
  --blame               Report time spent on each plugin
  --lang                Define locale to use
  --only-failed, -F     Only show failed tests
  -v, --verbose         Increase verbosity of output (may be specified more
                        than once)
  -d {INFO,DEBUG,WARNING,ERROR,CRITICAL}, --loglevel {INFO,DEBUG,WARNING,ERROR,CRITICAL}
                        Set log level
  -q, --quiet           Enable quiet mode

Filtering options:
  -i SUBSTRING, --include SUBSTRING
                        Only include plugins that contain substring
  -x SUBSTRING, --exclude SUBSTRING
                        Exclude plugins that contain substring

Config options:
  --dump-config         Dump config to console to be saved into file
  --no-config           Do not read configuration from file ~/DEVEL
                        /citellus/citellusclient/citellus.conf or
                        ~/.citellus.conf
```

## Plugins and their descriptions
This is new feature of citellus that will show you available scripts and their description.

```
./citellus.py --list-plugins --description
{'backend': 'core', 'description': 'This plugin checks if Apache reaches its MaxRequestWorkers', 'plugin': '/home/iranzo/DEVEL/citellus/citellusclient/plugins/core/bugzilla/httpd/1406417.sh'}
{'backend': 'core', 'description': 'Checks missconfigured host in nova vs hostname', 'plugin': '/home/iranzo/DEVEL/citellus/citellusclient/plugins/core/bugzilla/openstack/ceilometer/1483456.sh'}
{'backend': 'core', 'description': 'Checks for outdated ceph packages', 'plugin': '/home/iranzo/DEVEL/citellus/citellusclient/plugins/core/bugzilla/openstack/ceph/1358697.sh'}
{'backend': 'core', 'description': 'Checks httpd WSGIApplication defined to avoid wrong redirection', 'plugin': '/home/iranzo/DEVEL/citellus/citellusclient/plugins/core/bugzilla/openstack/httpd/1478042.sh'}
{'backend': 'core', 'description': 'Checks for keystone transaction errors on cleanup', 'plugin': '/home/iranzo/DEVEL/citellus/citellusclient/plugins/core/bugzilla/openstack/keystone/1473713.sh'}
{'backend': 'core', 'description': 'Checks for keystone LDAP domain template problem', 'plugin': '/home/iranzo/DEVEL/citellus/citellusclient/plugins/core/bugzilla/openstack/keystone/templates/1519057.sh'}
{'backend': 'core', 'description': 'Checks for wrong auth_url configuration in metadata_agent.ini', 'plugin': '/home/iranzo/DEVEL/citellus/citellusclient/plugins/core/bugzilla/openstack/neutron/1340001.sh'}
{'backend': 'core', 'description': 'Checks python-ryu tracebacks', 'plugin': '/home/iranzo/DEVEL/citellus/citellusclient/plugins/core/bugzilla/openstack/neutron/1450223.sh'}
```

## Doing a live check example
This is an example of execution of Citellus using all openstack and pacemaker tests collections.

```
./citellus.py -q -l -i pacemaker -i openstack
INFO:citellus:using default plugin path
# /root/citellus/citellus/plugins/bugzilla/openstack/ceilometer_bug_1483456.sh: failed
    https://bugzilla.redhat.com/show_bug.cgi?id=1483456
# /root/citellus/citellus/plugins/bugzilla/openstack/ceph_bug_1358697.sh: failed
    outdated ceph packages: https://bugzilla.redhat.com/show_bug.cgi?id=1358697
# /root/citellus/citellus/plugins/bugzilla/openstack/httpd_bug_1478042.sh: skipped
# /root/citellus/citellus/plugins/bugzilla/openstack/keystone_bug_1473713.sh: okay
# /root/citellus/citellus/plugins/bugzilla/openstack/neutron_bug_1450223.sh: skipped
# /root/citellus/citellus/plugins/bugzilla/openstack/neutron_bug_1474092.sh: okay
# /root/citellus/citellus/plugins/bugzilla/openstack/neutron_bug_1489066.sh: okay
# /root/citellus/citellus/plugins/bugzilla/openstack/nova_bug_1474092.sh: okay
# /root/citellus/citellus/plugins/bugzilla/openstack/swift_bug_1500607.sh: failed
    swift expirer https://bugzilla.redhat.com/show_bug.cgi?id=1500607
# /root/citellus/citellus/plugins/launchpad/openstack/keystone_bug_1649616.sh: okay
# /root/citellus/citellus/plugins/openstack/ceilometer/expiration.sh: failed
    ceilometer.conf setting must be updated:
    alarm_history_time_to_live = -1
    ceilometer.conf setting must be updated:
    event_time_to_live = -1
    ceilometer.conf setting must be updated:
    metering_time_to_live = -1
```

## Doing a fs snapshot check example
This is an example of execution of Citellus using ```pacemaker``` and ```openstack``` filter against fs snapshot.

```
./citellus.py -q -i pacemaker -i openstack sosreport-undercloud-0.redhat.local-20171117212710/
INFO:citellus:using default plugin path
# /root/citellus/citellus/plugins/bugzilla/openstack/ceilometer_bug_1483456.sh: failed
    https://bugzilla.redhat.com/show_bug.cgi?id=1483456
# /root/citellus/citellus/plugins/bugzilla/openstack/ceph_bug_1358697.sh: failed
    outdated ceph packages: https://bugzilla.redhat.com/show_bug.cgi?id=1358697
# /root/citellus/citellus/plugins/bugzilla/openstack/httpd_bug_1478042.sh: skipped
# /root/citellus/citellus/plugins/bugzilla/openstack/keystone_bug_1473713.sh: okay
# /root/citellus/citellus/plugins/bugzilla/openstack/neutron_bug_1450223.sh: skipped
# /root/citellus/citellus/plugins/bugzilla/openstack/neutron_bug_1474092.sh: okay
# /root/citellus/citellus/plugins/bugzilla/openstack/neutron_bug_1489066.sh: okay
# /root/citellus/citellus/plugins/bugzilla/openstack/nova_bug_1474092.sh: okay
# /root/citellus/citellus/plugins/bugzilla/openstack/swift_bug_1500607.sh: failed
    swift expirer https://bugzilla.redhat.com/show_bug.cgi?id=1500607
# /root/citellus/citellus/plugins/launchpad/openstack/keystone_bug_1649616.sh: okay
# /root/citellus/citellus/plugins/openstack/ceilometer/expiration.sh: failed
    ceilometer.conf setting must be updated:
    alarm_history_time_to_live = -1
    ceilometer.conf setting must be updated:
    event_time_to_live = -1
    ceilometer.conf setting must be updated:
    metering_time_to_live = -1
```

## HTML Interface
- Create by using `--output $FOLDER` and `--web`, open the generated `citellus.html`.

<img src="doc/images/www.png" height="40%" border=0>

## Ansible playbooks
Citellus can also run Ansible playbooks via extension

The are some additional conventions that are detailed in [ansible-playbooks.md](doc/ansible-playbooks.md) that determine how to code them to be executed in live or snapshoot mode.

Commands have been extended to allow `--list-plugins` to list them and include /exclude filters to work with them.

All of them must end in `.yml`.

~~~
found #1 extensions / found #0 tests at default path
mode: fs snapshot .
# Running extension ansible-playbook
# /home/iranzo/DEVEL/citellus/citellus/playbooks/system/clock-ntpstat.yml: skipped
    Skipped for incompatible operating mode
~~~

vs

~~~
found #2 extensions with #2 plugins
mode: live
# /home/iranzo/DEVEL/citellus/citellusclient/plugins/ansible/openstack/rabbitmq/ha-policies.yml: okay
# /home/iranzo/DEVEL/citellus/citellusclient/plugins/ansible/system/clock-ntpstat.yml: failed
    {"changed": false, "cmd": "ntpstat", "msg": "[Errno 2] No such file or directory", 

~~~

## Contact us!!
You can reach to us via:
- irc at #citellus in Freenode
- our mailing list:
    - <mailto:citellus-dev@redhat.com>
    - <https://www.redhat.com/mailman/listinfo/citellus-dev>
