# Introduction

Citellus is a program that should help faster identify common pitfails of OpenStack deployments from sosreports.

Please if you have any idea on any improvements please do not hesitate to open an issue.

## Usage

```

[root@undercloud-0 citellus]# ./citellus -h
_________ .__  __         .__  .__                
\_   ___ \|__|/  |_  ____ |  | |  |  __ __  ______
/    \  \/|  \   __\/ __ \|  | |  | |  |  \/  ___/
\     \___|  ||  | \  ___/|  |_|  |_|  |  /\___ \ 
 \______  /__||__|  \___  >____/____/____//____  >
        \/              \/                     \/ 

Usage: citellus [-hv] [-d warn,good,bad] [-m live,sosreport] [-p openstack,other] [-f DIRECTORY]...
Do stuff with sosreport and write the result to standard output.

              -h                  display this help and exit
              -f sosreport-*      opens a sosreport directory for analysis
              -d warn,good,bad    will display only filtered messages
              -p openstack,other  select plugin to run from plugins
              -m live,sosreport   select check mode, either sosreport or live
              -v                  verbose mode.


```

## Doing a live check example

> -m live,sosreport select check mode, either sosreport or live

```
[root@undercloud-0 citellus]# ./citellus -p openstack -m live
_________ .__  __         .__  .__                
\_   ___ \|__|/  |_  ____ |  | |  |  __ __  ______
/    \  \/|  \   __\/ __ \|  | |  | |  |  \/  ___/
\     \___|  ||  | \  ___/|  |_|  |_|  |  /\___ \ 
 \______  /__||__|  \___  >____/____/____//____  >
        \/              \/                     \/ 
Live check executed at Thu Jun 29 10:40:29 EDT 2017
Hostname: undercloud-0.redhat.local
Discovered node: director
Version: liberty
+-----------------------------------------------------------------------------+
| Traceback module                                                            |
+--------------------------------------------+--------------------------------|
| PASS: 23        FAILED: 1      WARNING: 8  |                Result: FAILED  |
+-----------------------------------------------------------------------------+
WARNING: Traceback module: /var/log/ceilometer/agent-notification.log (1 times)
WARNING: Traceback module: /var/log/ceilometer/alarm-evaluator.log (1 times)
PASS:    Traceback module: /var/log/ceilometer/alarm-notifier.log (0 times)
PASS:    Traceback module: /var/log/ceilometer/api.log (0 times)
PASS:    Traceback module: /var/log/ceilometer/ceilometer-dbsync.log (0 times)
FAILED:  Traceback module: /var/log/ceilometer/central.log (1175 times)
PASS:    Traceback module: /var/log/ceilometer/collector.log (0 times)
WARNING: Traceback module: /var/log/glance/api.log (9 times)
PASS:    Traceback module: /var/log/glance/registry.log (0 times)
PASS:    Traceback module: /var/log/heat/heat-api-cfn.log (0 times)
PASS:    Traceback module: /var/log/heat/heat-api-cloudwatch.log (0 times)
PASS:    Traceback module: /var/log/heat/heat-api.log (0 times)
PASS:    Traceback module: /var/log/heat/heat-engine.log (0 times)
PASS:    Traceback module: /var/log/keystone/keystone.log (0 times)
WARNING: Traceback module: /var/log/neutron/dhcp-agent.log (4 times)
WARNING: Traceback module: /var/log/neutron/openvswitch-agent.log (1 times)
PASS:    Traceback module: /var/log/neutron/ovs-cleanup.log (0 times)
PASS:    Traceback module: /var/log/neutron/server.log (0 times)
WARNING: Traceback module: /var/log/nova/nova-api.log (41 times)
PASS:    Traceback module: /var/log/nova/nova-cert.log (0 times)
WARNING: Traceback module: /var/log/nova/nova-compute.log (2 times)
WARNING: Traceback module: /var/log/nova/nova-conductor.log (1 times)
PASS:    Traceback module: /var/log/nova/nova-manage.log (0 times)
PASS:    Traceback module: /var/log/nova/nova-scheduler.log (0 times)
PASS:    Traceback module: /var/log/swift/swift.log (0 times)
PASS:    Traceback module: /var/log/httpd/default_error.log (0 times)
PASS:    Traceback module: /var/log/httpd/ironic_access.log (0 times)
PASS:    Traceback module: /var/log/httpd/ironic_error.log (0 times)
PASS:    Traceback module: /var/log/httpd/keystone_wsgi_admin_access.log (0 times)
PASS:    Traceback module: /var/log/httpd/keystone_wsgi_admin_error.log (0 times)
PASS:    Traceback module: /var/log/httpd/keystone_wsgi_main_access.log (0 times)
PASS:    Traceback module: /var/log/httpd/keystone_wsgi_main_error.log (0 times)
```

## Doing a sosreport check example

```
[root@undercloud-0 citellus]# ./citellus -p openstack -m sosreport -f ../sosreport-controller-1.localdomain-20170705201135/
_________ .__  __         .__  .__                
\_   ___ \|__|/  |_  ____ |  | |  |  __ __  ______
/    \  \/|  \   __\/ __ \|  | |  | |  |  \/  ___/
\     \___|  ||  | \  ___/|  |_|  |_|  |  /\___ \ 
 \______  /__||__|  \___  >____/____/____//____  >
        \/              \/                     \/ 
SOSreport was created at Wed Jul  5 20:12:08 UTC 2017
Hostname: controller-1.localdomain
Discovered node: controller
Version: mitaka
+-----------------------------------------------------------------------------+
| Traceback module                                                            |
+--------------------------------------------+--------------------------------|
| PASS: 13        FAILED: 2      WARNING: 6  |                Result: FAILED  |
+-----------------------------------------------------------------------------+
PASS:    Traceback module: ../sosreport-controller-1.localdomain-20170705201135//var/log/ceilometer/agent-notification.log (0 times)
FAILED:  Traceback module: ../sosreport-controller-1.localdomain-20170705201135//var/log/ceilometer/alarm-evaluator.log (1907 times)
PASS:    Traceback module: ../sosreport-controller-1.localdomain-20170705201135//var/log/ceilometer/alarm-notifier.log (0 times)
PASS:    Traceback module: ../sosreport-controller-1.localdomain-20170705201135//var/log/ceilometer/api.log (0 times)
FAILED:  Traceback module: ../sosreport-controller-1.localdomain-20170705201135//var/log/ceilometer/central.log (125 times)
PASS:    Traceback module: ../sosreport-controller-1.localdomain-20170705201135//var/log/glance/api.log (0 times)
PASS:    Traceback module: ../sosreport-controller-1.localdomain-20170705201135//var/log/glance/registry.log (0 times)
PASS:    Traceback module: ../sosreport-controller-1.localdomain-20170705201135//var/log/heat/heat-api-cfn.log (0 times)
PASS:    Traceback module: ../sosreport-controller-1.localdomain-20170705201135//var/log/heat/heat-api-cloudwatch.log (0 times)
PASS:    Traceback module: ../sosreport-controller-1.localdomain-20170705201135//var/log/heat/heat-api.log (0 times)
WARNING: Traceback module: ../sosreport-controller-1.localdomain-20170705201135//var/log/heat/heat-engine.log (20 times)
PASS:    Traceback module: ../sosreport-controller-1.localdomain-20170705201135//var/log/keystone/keystone.log (0 times)
PASS:    Traceback module: ../sosreport-controller-1.localdomain-20170705201135//var/log/neutron/dhcp-agent.log (0 times)
PASS:    Traceback module: ../sosreport-controller-1.localdomain-20170705201135//var/log/neutron/l3-agent.log (0 times)
WARNING: Traceback module: ../sosreport-controller-1.localdomain-20170705201135//var/log/nova/nova-api.log (3 times)
WARNING: Traceback module: ../sosreport-controller-1.localdomain-20170705201135//var/log/nova/nova-conductor.log (18 times)
WARNING: Traceback module: ../sosreport-controller-1.localdomain-20170705201135//var/log/nova/nova-consoleauth.log (5 times)
PASS:    Traceback module: ../sosreport-controller-1.localdomain-20170705201135//var/log/nova/nova-manage.log (0 times)
PASS:    Traceback module: ../sosreport-controller-1.localdomain-20170705201135//var/log/nova/nova-novncproxy.log (0 times)
WARNING: Traceback module: ../sosreport-controller-1.localdomain-20170705201135//var/log/nova/nova-scheduler.log (1 times)
WARNING: Traceback module: ../sosreport-controller-1.localdomain-20170705201135//var/log/swift/swift.log (3 times)
```

## Writing checks

Citellus tests should conform to the following standards:

- The test script must be executable. Citellus will ignore tests for
  which it does not have execute permission.

- The test should return one of the following error codes to indicate
  the test result:

    - 0 -- success
    - 1 -- failure
    - 2 -- skipped

A test may make use of the following standard environment variables:

- `$CITELLUS_ROOT` -- tests that parse files should locate them
  relative to this directory.  For example, if your script needs to
  examine `/etc/sysctl.conf`, it might have something like:

          if grep -q '^net.ipv4.ip_forward = 1' "${CITELLUS_ROOT}/etc/sysctl.conf"; then
              ...
          fi
- `$CITELLUS_LIVE` -- if `0`, tests are running against a filesystem
  snapshot of some sort.  Tests should not attempt to use commands
  that interrogate the system on which it is running.  If this
  variable is `1`, the tests are running on a live system.
