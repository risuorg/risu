## Introduction

Citellus is a program that should help faster identify common pitfails of OpenStack deployments from sosreports.

Please if you have any idea on any improvements please do not hesitate to open an issue.

### Usage

```bash
[root@undercloud-0 citellus]# ./citellus -h
_________ .__  __         .__  .__                
\_   ___ \|__|/  |_  ____ |  | |  |  __ __  ______
/    \  \/|  \   __\/ __ \|  | |  | |  |  \/  ___/
\     \___|  ||  | \  ___/|  |_|  |_|  |  /\___ \ 
 \______  /__||__|  \___  >____/____/____//____  >
        \/              \/                     \/ 

Usage: citellus [-hv] [-d warn,good,bad] [-f DIRECTORY]...
Do stuff with sosreport and write the result to standard output.

              -h                  display this help and exit
              -f sosreport-*      opens a sosreport directory for analysis
              -d warn,good,bad    will display only filtered messages
              -v                  verbose mode.
[root@undercloud-0 citellus]# 
```

### Example filtered output

```bash
[root@undercloud-0 citellus]# ./citellus -d warn,bad -f ../sosreport-testuser.12345-20170611185638
_________ .__  __         .__  .__                
\_   ___ \|__|/  |_  ____ |  | |  |  __ __  ______
/    \  \/|  \   __\/ __ \|  | |  | |  |  \/  ___/
\     \___|  ||  | \  ___/|  |_|  |_|  |  /\___ \ 
 \______  /__||__|  \___  >____/____/____//____  >
        \/              \/                     \/ 
SOSreport was created at Sun Jun 11 18:56:46 UTC 2017
Hostname: controller-0.localdomain
Discovered node: controller
Version: Red Hat OpenStack Platform 8/Liberty
+--------------------------------------------+
|               Traceback Module             |
+--------------------------------------------+
+--------------------------------------------+
|             Checking HA Cluster            |
+--------------------------------------------+
[WRONG] Checking stonith-enabled:.*true is in ../sosreport-testuser.12345-20170611185638/sos_commands/pacemaker/pcs_config
+--------------------------------------------+
|               Checking cronjob             |
+--------------------------------------------+
+--------------------------------------------+
|               My Custom Module             |
+--------------------------------------------+
+--------------------------------------------+
|             Python Hello Module            |
+--------------------------------------------+
Hello from python module!
Working directory is  ../sosreport-testuser.12345-20170611185638
+--------------------------------------------+
|                 httpd Module               |
+--------------------------------------------+
+--------------------------------------------+
|        Checking Hardware Requirements      |
+--------------------------------------------+
[WRONG] Uh, oh, controller requires at least 32GB of RAM
+--------------------------------------------+
|              Checking RabbitMQ             |
+--------------------------------------------+

```

### Example non-filtered output

```bash
[root@undercloud-0 citellus]# ./citellus -f ../sosreport-testuser.12345-20170611185638
_________ .__  __         .__  .__                
\_   ___ \|__|/  |_  ____ |  | |  |  __ __  ______
/    \  \/|  \   __\/ __ \|  | |  | |  |  \/  ___/
\     \___|  ||  | \  ___/|  |_|  |_|  |  /\___ \ 
 \______  /__||__|  \___  >____/____/____//____  >
        \/              \/                     \/ 
SOSreport was created at Sun Jun 11 18:56:46 UTC 2017
Hostname: controller-0.localdomain
Discovered node: controller
Version: Red Hat OpenStack Platform 8/Liberty
+--------------------------------------------+
|               Traceback Module             |
+--------------------------------------------+
[OK] No match for word Traceback in ../sosreport-testuser.12345-20170611185638/var/log/ceilometer/agent-notification.log
[OK] No match for word Traceback in ../sosreport-testuser.12345-20170611185638/var/log/ceilometer/alarm-evaluator.log
[OK] No match for word Traceback in ../sosreport-testuser.12345-20170611185638/var/log/ceilometer/alarm-notifier.log
[OK] No match for word Traceback in ../sosreport-testuser.12345-20170611185638/var/log/ceilometer/api.log
[OK] No match for word Traceback in ../sosreport-testuser.12345-20170611185638/var/log/ceilometer/ceilometer-dbsync.log
[OK] No match for word Traceback in ../sosreport-testuser.12345-20170611185638/var/log/ceilometer/central.log
[OK] No match for word Traceback in ../sosreport-testuser.12345-20170611185638/var/log/ceilometer/collector.log
[OK] No match for word Traceback in ../sosreport-testuser.12345-20170611185638/var/log/glance/api.log
[OK] No match for word Traceback in ../sosreport-testuser.12345-20170611185638/var/log/glance/registry.log
[OK] No match for word Traceback in ../sosreport-testuser.12345-20170611185638/var/log/heat/heat-api-cfn.log
[OK] No match for word Traceback in ../sosreport-testuser.12345-20170611185638/var/log/heat/heat-api-cloudwatch.log
[OK] No match for word Traceback in ../sosreport-testuser.12345-20170611185638/var/log/heat/heat-api.log
[OK] No match for word Traceback in ../sosreport-testuser.12345-20170611185638/var/log/heat/heat-engine.log
[OK] No match for word Traceback in ../sosreport-testuser.12345-20170611185638/var/log/keystone/keystone.log
[OK] No match for word Traceback in ../sosreport-testuser.12345-20170611185638/var/log/neutron/dhcp-agent.log
[OK] No match for word Traceback in ../sosreport-testuser.12345-20170611185638/var/log/neutron/l3-agent.log
[OK] No match for word Traceback in ../sosreport-testuser.12345-20170611185638/var/log/neutron/metadata-agent.log
[OK] No match for word Traceback in ../sosreport-testuser.12345-20170611185638/var/log/neutron/netns-cleanup.log
[OK] No match for word Traceback in ../sosreport-testuser.12345-20170611185638/var/log/neutron/openvswitch-agent.log
[OK] No match for word Traceback in ../sosreport-testuser.12345-20170611185638/var/log/nova/nova-api.log
[OK] No match for word Traceback in ../sosreport-testuser.12345-20170611185638/var/log/nova/nova-conductor.log
[OK] No match for word Traceback in ../sosreport-testuser.12345-20170611185638/var/log/nova/nova-consoleauth.log
[OK] No match for word Traceback in ../sosreport-testuser.12345-20170611185638/var/log/nova/nova-manage.log
[OK] No match for word Traceback in ../sosreport-testuser.12345-20170611185638/var/log/nova/nova-novncproxy.log
[OK] No match for word Traceback in ../sosreport-testuser.12345-20170611185638/var/log/nova/nova-scheduler.log
[OK] No match for word Traceback in ../sosreport-testuser.12345-20170611185638/var/log/swift/swift.log
+--------------------------------------------+
|             Checking HA Cluster            |
+--------------------------------------------+
[OK] The nodes in cluster are equal to 3.
[WRONG] Checking stonith-enabled:.*true is in ../sosreport-testuser.12345-20170611185638/sos_commands/pacemaker/pcs_config
[OK] Checking Failed Actions is NOT in ../sosreport-testuser.12345-20170611185638/sos_commands/pacemaker/pcs_status
[OK] Checking Stopped is NOT in ../sosreport-testuser.12345-20170611185638/sos_commands/pacemaker/pcs_status
+--------------------------------------------+
|               Checking cronjob             |
+--------------------------------------------+
[OK] Checking keystone-manage token_flush is in ../sosreport-testuser.12345-20170611185638/var/spool/cron/keystone
[OK] Checking heat-manage purge_deleted is in ../sosreport-testuser.12345-20170611185638/var/spool/cron/heat
+--------------------------------------------+
|               My Custom Module             |
+--------------------------------------------+
[OK] No match for word Got error 5 during COMMIT in ../sosreport-testuser.12345-20170611185638/var/log/keystone/keystone.log
[OK] Checking neutron.*failed|openstack.*failed is NOT in ../sosreport-testuser.12345-20170611185638/sos_commands/systemd/systemctl_list-units_--all
+--------------------------------------------+
|             Python Hello Module            |
+--------------------------------------------+
Hello from python module!
Working directory is  ../sosreport-testuser.12345-20170611185638
+--------------------------------------------+
|                 httpd Module               |
+--------------------------------------------+
[OK] No match for word MaxRequestWorkers in ../sosreport-testuser.12345-20170611185638/var/log/httpd/error_log
[OK] Checking httpd.*failed is NOT in ../sosreport-testuser.12345-20170611185638/sos_commands/systemd/systemctl_list-units_--all
+--------------------------------------------+
|        Checking Hardware Requirements      |
+--------------------------------------------+
[WRONG] Uh, oh, controller requires at least 32GB of RAM
[OK] Checking vmx\|svm is in ../sosreport-testuser.12345-20170611185638/proc/cpuinfo
[OK] A minimum of 40GB of available disk space
[OK] There is at least 5GB of free disk space
+--------------------------------------------+
|              Checking RabbitMQ             |
+--------------------------------------------+
[OK] There are currently 65436 file_descriptors available.
[OK] No match for word AMQP server on .* is unreachable in ../sosreport-testuser.12345-20170611185638/var/log/ceilometer/agent-notification.log
[OK] No match for word AMQP server on .* is unreachable in ../sosreport-testuser.12345-20170611185638/var/log/ceilometer/alarm-evaluator.log
[OK] No match for word AMQP server on .* is unreachable in ../sosreport-testuser.12345-20170611185638/var/log/ceilometer/alarm-notifier.log
[OK] No match for word AMQP server on .* is unreachable in ../sosreport-testuser.12345-20170611185638/var/log/ceilometer/api.log
[OK] No match for word AMQP server on .* is unreachable in ../sosreport-testuser.12345-20170611185638/var/log/ceilometer/ceilometer-dbsync.log
[OK] No match for word AMQP server on .* is unreachable in ../sosreport-testuser.12345-20170611185638/var/log/ceilometer/central.log
[OK] No match for word AMQP server on .* is unreachable in ../sosreport-testuser.12345-20170611185638/var/log/ceilometer/collector.log
[OK] No match for word AMQP server on .* is unreachable in ../sosreport-testuser.12345-20170611185638/var/log/glance/api.log
[OK] No match for word AMQP server on .* is unreachable in ../sosreport-testuser.12345-20170611185638/var/log/glance/registry.log
[OK] No match for word AMQP server on .* is unreachable in ../sosreport-testuser.12345-20170611185638/var/log/heat/heat-api-cfn.log
[OK] No match for word AMQP server on .* is unreachable in ../sosreport-testuser.12345-20170611185638/var/log/heat/heat-api-cloudwatch.log
[OK] No match for word AMQP server on .* is unreachable in ../sosreport-testuser.12345-20170611185638/var/log/heat/heat-api.log
[OK] No match for word AMQP server on .* is unreachable in ../sosreport-testuser.12345-20170611185638/var/log/heat/heat-engine.log
[OK] No match for word AMQP server on .* is unreachable in ../sosreport-testuser.12345-20170611185638/var/log/keystone/keystone.log
[OK] No match for word AMQP server on .* is unreachable in ../sosreport-testuser.12345-20170611185638/var/log/neutron/dhcp-agent.log
[OK] No match for word AMQP server on .* is unreachable in ../sosreport-testuser.12345-20170611185638/var/log/neutron/l3-agent.log
[OK] No match for word AMQP server on .* is unreachable in ../sosreport-testuser.12345-20170611185638/var/log/neutron/metadata-agent.log
[OK] No match for word AMQP server on .* is unreachable in ../sosreport-testuser.12345-20170611185638/var/log/neutron/netns-cleanup.log
[OK] No match for word AMQP server on .* is unreachable in ../sosreport-testuser.12345-20170611185638/var/log/neutron/openvswitch-agent.log
[OK] No match for word AMQP server on .* is unreachable in ../sosreport-testuser.12345-20170611185638/var/log/nova/nova-api.log
[OK] No match for word AMQP server on .* is unreachable in ../sosreport-testuser.12345-20170611185638/var/log/nova/nova-conductor.log
[OK] No match for word AMQP server on .* is unreachable in ../sosreport-testuser.12345-20170611185638/var/log/nova/nova-consoleauth.log
[OK] No match for word AMQP server on .* is unreachable in ../sosreport-testuser.12345-20170611185638/var/log/nova/nova-manage.log
[OK] No match for word AMQP server on .* is unreachable in ../sosreport-testuser.12345-20170611185638/var/log/nova/nova-novncproxy.log
[OK] No match for word AMQP server on .* is unreachable in ../sosreport-testuser.12345-20170611185638/var/log/nova/nova-scheduler.log
[OK] No match for word AMQP server on .* is unreachable in ../sosreport-testuser.12345-20170611185638/var/log/swift/swift.log
```
