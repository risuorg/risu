---
title: Risu - Detecting common pitfalls of deployments
author: Pablo Iranzo Gómez

theme: "solarized"
highlightTheme: "Zenburn"
mode: selfcontained
revealOptions:
  transition: "cube"
  slideNumber: true
---

## [Risu](https://risuorg.github.io):

### Detecting common pitfalls of deployments

<img src="../risu.png" width="202" height="202" border=0>

<https://risuorg.github.io>

---

## What is Risu?

- Risu is a framework populated by community-contributed scripts that automate detecting problems, including configuration issues, conflicts with package versions, and more.

---

## History: how did was it started?

- The tool, was started by [Robin Černín](https://zerodayz.github.io/) after a long weekend shift checking one and over again several sosreports for the same data on different hosts.

- It started with some tests + shell wrapper, and was added a python wrapper by [Pablo Iranzo](https://iranzo.github.io) to bring in more powerful features.

- After some design discussions with Engineering, a simpler reporting and design of tests was implemented.

---

## What can you do with Risu?

- Run against a sosreport or live environment.
- Solve issues faster thanks to the information it provides.
- Use the community-provided plugins for detecting actual or potential issues.
- Code new plugins in your language of choice (bash, python, ruby, etc.) to extend functionality.
  - Contribute them upstream for others to benefit.
- Use that information as part of proactive insights about the systems.

---

## Real life examples?

- For example, with Risu you can detect:
  - Failed keystone token purges.
  - missing parameters in expired ceilometer data, which can lead to filling up your hard drive.
  - unsynced ntp.
  - outdated packages that have known critical issues.
  - others! (200+ plugins as of this writing some of them with more than one issue detected)
- Whatever else you can imagine or code 😉

---

## Some numbers on plugin count (862):

<small>
<small>
- healthcheck : 79
- informative : 2
- negative : 3 ['system: 1', 'system/iscsi: 1']
- openshift : 5
- openstack : 4 ['rabbitmq: 1']
- ovirt-rhv : 1
- pacemaker : 2
- positive : 35 ['cluster/cman: 1', 'openstack: 16', 'openstack/ceilometer: 1', 'system: 1']
- rhinternal : 697 ['bugzilla/docker: 1', 'bugzilla/httpd: 1', 'bugzilla/openstack/ceilometer: 1', 'bugzilla/openstack/ceph: 1', 'bugzilla/openstack/cinder: 1', - 'bugzilla/openstack/httpd: 1', 'bugzilla/openstack/keystone: 1', 'bugzilla/openstack/keystone/templates: 1', 'bugzilla/openstack/neutron: 5', 'bugzilla/openstack/nova: 4', 'bugzilla/openstack/swift: 1', 'bugzilla/openstack/tripleo: 2', 'bugzilla/systemd: 1', 'ceph: 4', 'cifs: 5', 'docker: 1', 'httpd: 1', 'launchpad/openstack/keystone: 1', 'launchpad/openstack/oslo.db: 1', 'network: 7', 'ocp-pssa/etcd: 1', 'ocp-pssa/master: 12', 'ocp-pssa/node: 14', 'openshift/cluster: 1', 'openshift/etcd: 2', 'openshift/node: 1', 'openshift/ocp-pssa/master: 2', 'openstack: 6', 'openstack/ceilometer: 2', 'openstack/ceph: 1', 'openstack/cinder: 5', 'openstack/containers: 4', 'openstack/containers/docker: 2', 'openstack/containers/rabbitmq: 1', 'openstack/crontab: 4', 'openstack/glance: 1', 'openstack/haproxy: 2', 'openstack/hardware: 1', 'openstack/iptables: 1', 'openstack/keystone: 3', 'openstack/mysql: 8', 'openstack/network: 6', 'openstack/neutron: 5', 'openstack/nova: 12', 'openstack/openvswitch: 3', 'openstack/pacemaker: 1', 'openstack/rabbitmq: 5', 'openstack/redis: 1', 'openstack/swift: 3', 'openstack/system: 4', 'openstack/systemd: 1', 'pacemaker: 10', 'satellite: 1', 'security: 3', 'security/meltdown: 2', 'security/spectre: 8', 'security/speculative-store-bypass: 8', 'storage: 1', 'sumsos/bugzilla: 11', 'sumsos/kbases: 426', 'supportability: 11', 'sysinfo: 2', 'system: 56', 'virtualization: 2']
- supportability : 3 ['openshift: 1']
- sysinfo : 18 ['lifecycle: 6', 'openshift: 4', 'openstack: 2']
- system : 12 ['iscsi: 1']
- virtualization : 1
</small>
</small>

---

## The goal

- Be so damn simple to write new plugins that anyone can do them.
- Write tests in whatever language (bash, python, perl, etc) as long as they conform to some standards.
- Allow anyone to submit new plugins.

---

## How to run it manually?

<img src="../images/risurun.png" width="80%" border=0><!-- .element height="50%"  width="90%" -->

Note: Change speaker after this

---

## Highlights

<small>

- Plugins in your language of choice.
- Allows dumping output to json file to be processed by other tools.
  - Allow the visualization of html from the json output.
- Ansible playbook support (live and snapshot if crafted playbooks)
  - Core implemented as extension to easily expand with new ones.
- Save / restore default settings.
- Run via pip/pipsi if you don't want to git clone from repo or using a container.

</small>

---

## HTML Interface

<small>
Create by using --web, open the generated `risu.html` over http.
<img src="../images/www.png" width="80%" border=0><!-- .element height="50%"  width="70%" -->
</small>
---

## Why upstream?

<small>

- This is an open source project. All the scripts should be committed upstream and shared (and we are willing to foster this).
  - Project on GitHub: <https://github.com/risuorg/risu/>
- We want contributions from anyone.
- We follow an approach similar to other opensource projects: we use Gerrit for reviewing the code and UT's for validating basic functionality.

</small>

---

## How do I contribute?

<small>

At the moment, there’s a strong presence on OpenStack plugins as it is where we solve our issues on everyday basis, but allows anything, as long as there are tests written for it.

For example, it will be easy to report on systems registered against RHN instead of CDN or systems with a specific version of pacemaker known to have lot of issues or check amount of free memory or memory usage from a process.

Read contributing doc at: <https://github.com/risuorg/risu/blob/master/CONTRIBUTING.md> for more details.

</small>

---

## Risu vs other tools

- XSOS: Provides information on ram usage, etc, no analysis, more like a ‘fancy’ sosreport viewer.

- TripleO-validations: only runs live from the environment, for customer support most of times we cannot afford to do that.

---

## Why not sosreports?

<small>

- It’s not Risu or ‘sosreports’, SOS collects data from the system, Risu, runs tests/plugins against the data collected.
- Sosreport is installed in RHEL base channels, this makes it well spread, but also, slower to get changes.
- Frequently, data about errors or errors to be, is already in sosreports.
- Risu is based on known issues and easy to extend with new ones, requires faster devel cycle, targeting more a devops or support teams as target audience.

</small>

Note: Change speaker after this

---

## How does it work under the hood?

Philosophy is very simple:

- Risu is just a simple wrapper.
- Allows to specify on sosreport and test filters.
- Finds tests available in test folders.
- Executes each test against sosreport and reports return status.
- Framework written in python which features option parsing, parallel execution of tests, filtering, etc.

---

## What about the plugins?

Tests are even simpler:

- Written in whatever language as long as they can be executed from shell
- Output messages to ‘stderr’ (>&2)
- When using strings like echo \$”string” bash’s built-in i18n is used so you can translate to your language
- Return `$RC_OKAY` for success / `$RC_FAILED` for error / `$RC_SKIPPED` for skipped tests / `$RC_INFO` for informational tests / Other for unexpected error.

---

## What about the plugins? (continuation)

- Will inherit some env vars like root folder for sosreport (empty for live) (`RISU_ROOT`) or if running live (`RISU_LIVE`) that provide required details. No user input should be required.
- Live tests can, for example, query DB and ones in sosreport check values on logs.

---

## Some execution and script examples?

Check [disk usage](https://github.com/risuorg/risu/blob/master/risu/plugins/system/disk_usage.sh):

```sh
#!/bin/bash

# Load common functions
[ -f "${RISU_BASE}/common-functions.sh" ] && . "${RISU_BASE}/common-functions.sh"

# description: error if disk usage is greater than $RISU_DISK_MAX_PERCENT
: ${RISU_DISK_MAX_PERCENT=75}

if [[ $RISU_LIVE = 0 ]]; then
    is_required_file "${RISU_ROOT}/df"
    DISK_USE_CMD="cat ${RISU_ROOT}/df"
else
    DISK_USE_CMD="df -P"
fi

result=$($DISK_USE_CMD |awk -vdisk_max_percent=$RISU_DISK_MAX_PERCENT '/^\/dev/ && substr($5, 0, length($5)-1) > disk_max_percent { print $6,$5 }')

if [ -n "$result" ]; then
    echo "${result}" >&2
    exit $RC_FAILED
else
    exit $RC_OKAY
fi
```

---

## Ready for deep dive on tests?

- Each test should take care of checking if it should run or not and output return code and stderr. Wrapper just runs all the tests or specific ones (filtering options).

---

## Requirements:

- return code must be `$RC_OKAY` (ok), `$RC_FAILED` (failed), `$RC_SKIPPED` (skipped) or `$RC_INFO` (informational/warning).
- Messages to be printed on stderr are displayed on 'failed' or 'skipped' if verbose enabled.
- Running against ‘sosreport’, `RISU_ROOT` contains path to sosreport folder provided.
- `RISU_LIVE` contains `0` or `1` if running against live or not.

---

## How to start a new plugin (example)

- Write a script in `~/~/.../plugins/core/rhev/hosted-engine.sh`
- `chmod +x hosted-engine.sh`

---

## How to start a new plugin (continuation)

```sh
if [ “$RISU_LIVE” = “0” ]; then
    grep -q ovirt-hosted-engine-ha $RISU_ROOT/installed-rpms
    returncode=$?
    if [ “x$returncode” == “x0” ]; then
        exit $RC_OKAY
    else
        echo “ovirt-hosted-engine is not installed “ >&2
        exit $RC_FAILED
    fi
else
    echo “Not running on Live system” >&2
    exit $RC_SKIPPED
fi
```

---

## How to start a new plugin (with functions)

```sh
# Load common functions
[ -f "${RISU_BASE}/common-functions.sh" ] && . "${RISU_BASE}/common-functions.sh"

if is_rpm ovirt-hosted-engine-ha; then
    exit $RC_OKAY
else
    echo “ovirt-hosted-engine is not installed “ >&2
    exit $RC_FAILED
fi
```

---

## How to test your plugin?

- Use `tox` to run some UT's (utf8, bashate, python 2.7, python 3.5)

- Specify the plugin to use:

```sh
[piranzo@host risu]$ ~/risu/risu.py sosreport-20170724-175510/crta02 -i hosted-engine.sh
_________ .__  __         .__  .__
\_   ___ \|__|/  |_  ____ |  | |  |  __ __  ______
/    \  \/|  \   __\/ __ \|  | |  | |  |  \/  ___/
\     \___|  ||  | \  ___/|  |_|  |_|  |  /\___ \
 \______  /__||__|  \___  >____/____/____//____  >
        \/              \/                     \/
mode: fs snapshot sosreport-20170724-175510/crta02
# ~/~/.../plugins/core/rhev/hosted-engine.sh: failed
    “ovirt-hosted-engine is not installed “
```

---

## What is Magui

### Introduction

- Risu works on individual sosreports against a set of tests (all by default), but some problems require checks across several systems.

<small>For example, galera requires to check seqno across all controllers running database.</small>

---

### What does M.a.g.u.i. do?

- It runs risu against each sosreport, gathers and groups the data per plugin.
- Runs its own plugins against the data received to highlight issues that depend on several systems.
- Allows grabbing remote host data via ansible host lists.

---

## How does it look like?

<small>

It’s delivered in risu repo and can be executed by specifying sosreports:

```sh
[piranzo@collab-shell]$ ~/risu/magui.py * -i seqno
    _
  _( )_  Magui:
 (_(ø)_)
  /(_)   Multiple Analisis Generic Unifier and Interpreter
 \|
  |/
{'~/~/.../core/openstack/mysql/seqno.sh': {'controller0': {'err': u'2b65adb0-787e-11e7-81a8-26480628c14c:285019879\n',
                                                                'out': u'',
                                                                'rc': 10},
                                                'controller1': {'err': u'2b65adb0-787e-11e7-81a8-26480628c14c:285019879\n',
                                                                'out': u'',
                                                                'rc': 10},
                                                'controller2': {'err': u'2b65adb0-787e-11e7-81a8-26480628c14c:285019878\n',
                                                                'out': u'',
                                                                'rc': 10}}}
```

- In this example, UUID and SEQNO is shown for each controller and we can see that controller 2 has different SEQNO from the other two nodes.

</small>

---

## Next steps with Magui

- Some plugins as of this writing:
  - Aggregate data from risu sorted by plugin for quick comparison
  - Show 'metadata' extension separated to quickly compare across values
  - pipeline-yaml different across sosreports
  - seqno and highest seqno in galera
  - release check across hosts

---

## Action Items

- Add more plugins!
- Evangelize about the tool so we can work together in solving our common issues on the same framework.
- Get moving fast enough that the tool has continuity, other tools just died by having a ‘solo’ developer working in their spare time.
- Start implementing more tests in Magui that provide real intelligence (for example we do report and check on seqno or pipeline-yaml but lot of other issues can benefit from this).

---

## Other resources

Blog posts:
<small>

- Risu tagged posts: https://iranzo.github.io/blog/tag/risu/
- <http://iranzo.github.io/blog/2017/07/26/Risu-framework-for-detecting-known-issues/>
- <https://iranzo.github.io/blog/2017/07/31/Magui-for-analysis-of-issues-across-several-hosts/>
- <https://iranzo.github.io/blog/2017/08/17/Jenkins-for-running-CI-tests/>
- <https://iranzo.github.io/blog/2017/10/26/i18n-and-bash8-in-bash/>
- <https://iranzo.github.io/blog/2018/01/16/recent-changes-in-magui-and-risu/>
- DevConf.cz 2018 recording <https://www.youtube.com/watch?v=SDzzqrUdn5A>

</small>

---

## Questions?

THANK YOU FOR ATTENDING!!

For additional questions, come to #risu on [Libera](https://libera.chat/) or email us:

- https://risuorg.github.io
- risuorg _AT_ googlegroups.com
- <https://groups.google.com/forum/#!forum/risu>

---

### Quiz 1/4!!

<small>

1. What sort of logic are scripts using to determine if the check is failed/ok or should be skipped

   - Exit status for commands like `grep`, etc
   - Check requirements to run, target environment and matching details
   - bash conditionals
   - custom functions checks

</small>

Note:

<small>

1. Skipped: no requirements satisfied, ok: no problem detected, Fail: test is failed (2)

</small>

---

### Quiz 2/4!!

<small>

1. What do I need to do if I want to add my scripts

   - Modify risu.py to define new path
   - Use include filter to add it
   - chmod +x the script in the plugins folder
   - Append path to the script after sosreport

</small>

Note:

<small>

1. Create a new script, chmod +x and return valid status code (3)

</small>

---

### Quiz 3/4!!

<small>

1. What languages are supported for scripts?

   - bash, python, ruby
   - python, bash, c++
   - golang, perl
   - all of above

</small>

Note:

1. All of above

---

### Quiz 4/4!!

<small>

1. What are the valid return status for scripts?

   - RC_WARNING
   - RC_OKAY
   - RC_SKIPPED
   - RC_FAILED

</small>

Note:

1. RC_OKAY, RC_SKIPPED, RC_FAILED, RC_INFO
