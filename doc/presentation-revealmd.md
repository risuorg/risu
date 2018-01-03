---
title: Citellus - Detecting common pitfalls of deployments
author: Pablo Iranzo Gómez

theme: "solarized"
highlightTheme: "Zenburn"
transition: cube
mode: selfcontained
---

# [Citellus](https://github.com/zerodayz/citellus)

# [Citellus](https://github.com/zerodayz/citellus):
## Detecting common pitfalls of deployments

<img src="citellus.png" width="20%" border=0>

---

## What is Citellus?

- Citellus is a framework populated by community-contributed scripts that automate detecting problems, including configuration issues, conflicts with package versions, and more.

----

## History: how did was it started?

- The tool, started by Robin Černín after a long weekend shift checking one and over again several sosreports for the same data on different hosts.

- It started with some tests + shell wrapper, and was added a python wrapper by Pablo Iranzo to bring in more powerful features.

- After some design discussions with Engineering, a simpler reporting and design of tests was implemented.

---

## What can you do with Citellus?

- Run against a sosreport or live environment.<!-- .element: class="fragment" -->
- Solve issues faster thanks to the information it provides.<!-- .element: class="fragment" -->
- Use the community-provided plugins for detecting actual or potential issues.<!-- .element: class="fragment" -->
- Code new plugins in your language of choice (bash, python, ruby, etc.) to extend functionality.<!-- .element: class="fragment" -->
    - Contribute them upstream for others to benefit.<!-- .element: class="fragment" -->
- Use that information as part of proactive insights about the systems.<!-- .element: class="fragment" -->

---

## Real life examples?
- For example, with Citellus you can detect:
    - Failed keystone token purges.
    - missing parameters in expired ceilometer data, which can lead to filling up your hard drive.
    - unsynced ntp.
    - outdated packages that have known critical issues.
    - others! (101 plugins as of this writting some of them with more than one issue detected)
- Whatever else you can imagine or code 😉

----

## Some numbers on plugin count:

- bugzilla : 14
- launchpad : 1
- network : 1
- openstack : 54
- pacemaker : 7
- system : 23
- virtualization : 1

----

## More granular!!

<small>
bugzilla : 14 ['openstack/swift: 1', 'openstack/keystone/templates: 1', 'openstack/ceph: 1', 'httpd: 1', 'openstack/keystone: 1', 'openstack/ceilometer: 1', 'openstack/nova: 2', 'openstack/httpd: 1', 'systemd: 1', 'openstack/neutron: 4']

launchpad : 1 ['openstack/keystone: 1']

network : 1 []

openstack : 52 ['nova: 8', 'mysql: 6', 'rabbitmq: 3', 'containers/rabbitmq: 1', 'network: 3', 'containers/docker: 2', 'hardware: 1', 'containers: 4', 'cinder: 1', 'swift: 2', 'systemd: 1', 'iptables: 1', 'ceph: 4', 'keystone: 3', 'system: 1', 'redis: 1', 'crontab: 3', 'ceilometer: 3', 'glance: 1', 'neutron: 1']

pacemaker : 7 []

system : 23 []

virtualization : 1 []
</small>

---

## The goal

- Be so damn simple to write new plugins that anyone can do them.<!-- .element: class="fragment" -->
- Allow to write tests in whatever language of choice (bash, python, perl, etc) as long as they conform to some standards.<!-- .element: class="fragment" -->
- Allow anyone to submit new plugins.<!-- .element: class="fragment" -->

---

## How to run in manually?

As easy as it could:

~~~sh
citellus/citellus/citellus.py /folder/containing/sosreport
~~~

Example:

~~~
_________ .__  __         .__  .__                
\_   ___ \|__|/  |_  ____ |  | |  |  __ __  ______
/    \  \/|  \   __\/ __ \|  | |  | |  |  \/  ___/
\     \___|  ||  | \  ___/|  |_|  |_|  |  /\___ \ 
 \______  /__||__|  \___  >____/____/____//____  >
        \/              \/                     \/ 
                                                  
found #2 extensions with #94 plugins
mode: fs snapshot ../sosreport-controller-0-20171212110438/
# /home/iranzo/DEVEL/citellus/citellusclient/plugins/ansible/openstack/rabbitmq/ha-policies.yml: skipped
# /home/iranzo/DEVEL/citellus/citellusclient/plugins/ansible/system/clock-ntpstat.yml: skipped
# /home/iranzo/DEVEL/citellus/citellusclient/plugins/core/bugzilla/httpd/1406417.sh: okay
# /home/iranzo/DEVEL/citellus/citellusclient/plugins/core/bugzilla/openstack/keystone/1473713.sh: okay
# /home/iranzo/DEVEL/citellus/citellusclient/plugins/core/bugzilla/openstack/keystone/templates/1519057.sh: skipped
# /home/iranzo/DEVEL/citellus/citellusclient/plugins/core/bugzilla/openstack/nova/1474092.sh: okay
# /home/iranzo/DEVEL/citellus/citellusclient/plugins/core/bugzilla/openstack/nova/1527345.sh: skipped
# /home/iranzo/DEVEL/citellus/citellusclient/plugins/core/bugzilla/openstack/swift/1500607.sh: okay
# /home/iranzo/DEVEL/citellus/citellusclient/plugins/core/bugzilla/systemd/1172387.sh: okay
# /home/iranzo/DEVEL/citellus/citellusclient/plugins/core/launchpad/openstack/keystone/1649616.sh: okay
# /home/iranzo/DEVEL/citellus/citellusclient/plugins/core/network/external_connectivity.sh: skipped
# /home/iranzo/DEVEL/citellus/citellusclient/plugins/core/openstack/ceilometer/expiration.sh: failed
    alarm_history_time_to_live missing on file
    event_time_to_live missing on file
    metering_time_to_live missing on file
~~~

---

## Highlights
- Plugins in your language of choice.
- Allows to dump output to json file to be processed by other tools.
    - Allow to visualize html from json output.
- Ansible playbook support (live and snapshoot if crafted playbooks)
    - Core implemented as extension to easily expand.
- Save / restore default settings

----

## HTML Interface
- Create by using --output and --web, open the generated `citellus.html`.
<img src="images/www.png" height="40%" border=0>


---

## Why upstream?

- This is an open source project. All the scripts should be committed upstream and shared (and we are willing to foster this)
    - Project on GitHub: <https://github.com/zerodayz/citellus/>
- We want contributions to happen from anyone.
- We follow an approach similar to other opensource projects: we do use Gerrit for reviewing the code and UT's for validating basic functionality.

---

## How do I contribute?

At the moment, there’s a strong presence on OpenStack plugins as it is where we solve our issues on everyday basis, but allows anything, as long as there are tests written for it.

For example, it will be easy to report on systems registered against RHN instead of CDN or systems with a specific version of pacemaker known to have lot of issues or check amount of free memory or memory usage from a process.

<small> Read contributing doc at:  <https://github.com/zerodayz/citellus/blob/master/CONTRIBUTING.md> for more details.</small>

---

## How does it work under the hood?

Philosophy is very simple:
- Citellus is just a simple wrapper.<!-- .element: class="fragment" -->
- Allows to specify on sosreport and test folders<!-- .element: class="fragment" -->
- Finds tests available in test folders<!-- .element: class="fragment" -->
- Executes each test against sosreport and reports return status<!-- .element: class="fragment" -->
- Framework written in python (fallback to prior shell version) so features like parsing, parallel execution of tests, etc are available.<!-- .element: class="fragment" -->

---

## What about the plugins?

Tests are even simpler:
- Written in whatever language of choice as long as they can be executed from shell.
- Output messages to ‘stderr’ (>&2)
- When using strings like echo $”string” bash’s builting i18n is used so you can translate in your language.
- Return `$RC_OKAY` for success / `$RC_FAILED` for error / `$RC_SKIPPED` for skipped tests / Other for unexpected error

----

## What about the plugins? (continuation)

- Will inherit some env vars like root folder for sosreport (empty for live) (`CITELLUS_ROOT`) or if running live (`CITELLUS_LIVE`) that provide required details. No user input should be required.
- Live tests can for example query DB and ones in sosreport check values on logs

----

## Some execution and script examples?

Check [disk usage](<https://github.com/zerodayz/citellus/blob/master/citellus/plugins/system/disk_usage.sh>):

```sh
#!/bin/bash

# Load common functions
[ -f "${CITELLUS_BASE}/common-functions.sh" ] && . "${CITELLUS_BASE}/common-functions.sh"

# description: error if disk usage is greater than $CITELLUS_DISK_MAX_PERCENT
: ${CITELLUS_DISK_MAX_PERCENT=75}

if [[ $CITELLUS_LIVE = 0 ]]; then
    is_required_file "${CITELLUS_ROOT}/df"
    DISK_USE_CMD="cat ${CITELLUS_ROOT}/df"
else
    DISK_USE_CMD="df -P"
fi

result=$($DISK_USE_CMD |awk -vdisk_max_percent=$CITELLUS_DISK_MAX_PERCENT '/^\/dev/ && substr($5, 0, length($5)-1) > disk_max_percent { print $6,$5 }')

if [ -n "$result" ]; then
    echo "${result}" >&2
    exit $RC_FAILED
else
    exit $RC_OKAY
fi
```

---

## Citellus vs other tools

- XSOS
Provides information on ram usage, etc, no analysis, more like a ‘fancy’ sosreport viewer.

---

## Why not sosreports?

- It’s not Citellus or ‘sosreports’, SOS collects data from the system, Citellus, runs tests/plugins against the data collected.
- Sosreport is installed in RHEL base channels, this makes it well spread, but also, slower to get changes.
- Frequently, data about errors or errors to be, is already in sosreports.
- Citellus is based on known issues and easy to extend with new ones, requires faster devel cycle, targeting more a devops or support teams as target audience.

---

## Other resources
Blog post by Pablo:
<small>
- <http://iranzo.github.io/blog/2017/07/26/Citellus-framework-for-detecting-known-issues/>
- <https://iranzo.github.io/blog/2017/07/31/Magui-for-analysis-of-issues-across-several-hosts/>
- <https://iranzo.github.io/blog/2017/08/17/Jenkins-for-running-CI-tests/>

</small>

---

## Ready for deep dive on tests?

- There are more tests for OpenStack at the moment as this is the speciality where it started, but it’s open and able to extend to whatever is needed.

- Each test should take care of checking if it should run or not and output return code and stderr. Wrapper just runs all the tests or specific ones (filtering)

----

## How to start a new plugin (example)
- Write a script in `~/citellus/citellusclient/plugins/core/rhev/hosted-engine.sh`
- `chmod +x hosted-engine.sh`

----

## Requirements:
- return code must be `$RC_OKAY` (ok), `$RC_FAILED` (failed)  or `$RC_SKIPPED` (skipped)
- Messages to be printed on stderr are displayed on failed or ‘skipped’ if verbose enabled
- Running against ‘sosreport’, CITELLUS_ROOT contains path to sosreport folder provided.
- CITELLUS_LIVE contains 0 or 1 if running against live or not

----

## How to start a new plugin (continuation)

~~~sh
if [ “$CITELLUS_LIVE” = “0” ]; then
    grep -q ovirt-hosted-engine-ha $CITELLUS_ROOT/installed-rpms
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
~~~

----

## How to start a new plugin (with functions)

~~~sh
# Load common functions
[ -f "${CITELLUS_BASE}/common-functions.sh" ] && . "${CITELLUS_BASE}/common-functions.sh"

if is_rpm ovirt-hosted-engine-ha; then
    exit $RC_OKAY
else
        echo “ovirt-hosted-engine is not installed “ >&2
        exit $RC_FAILED
fi
~~~

----

## How to test your plugin?

- Use `tox` to run some UT's (utf8, bashate, python 2.7, python 3.5)

- Specify the plugin to use:
~~~sh
[piranzo@host citellus]$ ~/citellus/citellus/citellus.py sosreport-20170724-175510/crta02 -i hosted-engine.sh
_________ .__  __         .__  .__
\_   ___ \|__|/  |_  ____ |  | |  |  __ __  ______
/    \  \/|  \   __\/ __ \|  | |  | |  |  \/  ___/
\     \___|  ||  | \  ___/|  |_|  |_|  |  /\___ \
 \______  /__||__|  \___  >____/____/____//____  >
        \/              \/                     \/
mode: fs snapshot sosreport-20170724-175510/crta02
# /home/iranzo/citellus/citellusclient/plugins/core/rhev/hosted-engine.sh: failed
    “ovirt-hosted-engine is not installed “
~~~

---

## What is Magui
### Introduction
- Citellus works on individual sosreports against a set of tests (all by default), but some problems require checks across several systems.

<small>For example, galera requires to check seqno across all controllers running database.</small>

- What does M.a.g.u.i. Does?
    - It runs citellus against each sosreport, gathers and groups the data per plugin.

----

## How does it looks like?
It’s delivered in citellus repo and can be executed by specifying sosreports:
~~~sh
[piranzo@collab-shell sosreport-20171205-172438]$ ~/citellus/magui.py * -i seqno
    _
  _( )_  Magui:
 (_(ø)_)
  /(_)   Multiple Analisis Generic Unifier and Interpreter
 \|
  |/
{'/home/remote/piranzo/citellus/citellusclient/plugins/core/openstack/mysql/seqno.sh': {'controller0': {'err': u'2b65adb0-787e-11e7-81a8-26480628c14c:285019879\n',
                                                                                                                          'out': u'',
                                                                                                                          'rc': 10},
                                                                                        'controller1': {'err': u'2b65adb0-787e-11e7-81a8-26480628c14c:285019879\n',
                                                                                                                          'out': u'',
                                                                                                                          'rc': 10},
                                                                                        'controller2': {'err': u'2b65adb0-787e-11e7-81a8-26480628c14c:285019878\n',
                                                                                                                          'out': u'',
                                                                                                                          'rc': 10}}}
~~~

- On this example, UUID and SEQNO is shown for each controller and we can see that controller 2 has different SEQNO to the other two nodes.

----

## Next steps with Magui

- At the moment it aggregates the data outputted by scripts in citellus, the idea is to write other plugins Magui-specific that process on the data (a test in citellus might be ok, but could mean a failure when analyzed together with other sosreports)
- For example you can compare the seqno in galera database or ntp sync status across several controllers.


---

## Action Items
<small>
- Add more plugins<!-- .element: class="fragment" -->
- Evangelize about the tool so we can work together in solving our common issues on the same framework.<!-- .element: class="fragment" -->
- Get moving fast enough that the tool has continuity, other tools just died by having a ‘solo’ developer working on spare time<!-- .element: class="fragment" -->
- Start implementing some tests in Magui that provide real intelligence (for example we can report now on seqno, but we do not process that with a specific plugin that reports ‘error’ if one differs).<!-- .element: class="fragment" -->

</small>

---

## Are you still there?

THANK YOU FOR ATTENDING!!

For questions, come to #citellus on Freenode or email us:

- <mailto:citellus-dev@redhat.com>
- <https://www.redhat.com/mailman/listinfo/citellus-dev>