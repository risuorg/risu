## Introduction

Citellus is a program that should help faster identify common pitfails of OpenStack deployments from sosreports.

Please if you have any idea on any improvements please do not hesitate to open an issue.

### Usage

```
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

### Example of filtered messages

```
[root@undercloud-0 citellus]# ./citellus -f ../sosreport-testuser.12345-20170611105406 -d warn,bad
_________ .__  __         .__  .__                
\_   ___ \|__|/  |_  ____ |  | |  |  __ __  ______
/    \  \/|  \   __\/ __ \|  | |  | |  |  \/  ___/
\     \___|  ||  | \  ___/|  |_|  |_|  |  /\___ \ 
 \______  /__||__|  \___  >____/____/____//____  >
        \/              \/                     \/ 
SOSreport was created at Sun Jun 11 10:54:19 EDT 2017
Hostname: undercloud-0.redhat.local
Discovered node: osp-director
Version: Red Hat OpenStack Platform 8/Liberty
+-----------------------------------------------------------------------------+
| Traceback Module                                                            |
+--------------------------------------------+--------------------------------|
| PASS: 0         FAILED: 1      WARNING: 4  |                Result: FAILED  |
+-----------------------------------------------------------------------------+
[WARN] There are 1 occurences of word Traceback in ../sosreport-testuser.12345-20170611105406/var/log/ceilometer/alarm-evaluator.log
[WRONG] There are 92 occurences of word Traceback in ../sosreport-testuser.12345-20170611105406/var/log/ceilometer/central.log
[WARN] There are 9 occurences of word Traceback in ../sosreport-testuser.12345-20170611105406/var/log/glance/api.log
[WARN] There are 2 occurences of word Traceback in ../sosreport-testuser.12345-20170611105406/var/log/neutron/dhcp-agent.log
[WARN] There are 6 occurences of word Traceback in ../sosreport-testuser.12345-20170611105406/var/log/nova/nova-api.log
+-----------------------------------------------------------------------------+
| Checking cronjob                                                            |
+--------------------------------------------+--------------------------------|
| PASS: 0         FAILED: 0      WARNING: 1  |                Result: WARNING |
+-----------------------------------------------------------------------------+
[WARN] Missing file ../sosreport-testuser.12345-20170611105406/var/spool/cron/keystone
+-----------------------------------------------------------------------------+
| Checking Hardware Requirements                                              |
+--------------------------------------------+--------------------------------|
| PASS: 0         FAILED: 1      WARNING: 0  |                Result: FAILED  |
+-----------------------------------------------------------------------------+
[WRONG] Undercloud requires minimum 8-core 64-bit x86 processor
+-----------------------------------------------------------------------------+
| Checking Tuning options                                                     |
+--------------------------------------------+--------------------------------|
| PASS: 0         FAILED: 6      WARNING: 0  |                Result: FAILED  |
+-----------------------------------------------------------------------------+
[WRONG] Checking ^[ \t]*innodb_additional_mem_pool_size.*=.*20M is in ../sosreport-testuser.12345-20170611105406/etc/my.cnf.d/server.cnf
[WRONG] Checking ^[ \t]*innodb_buffer_pool_size.*=.*1000M is in ../sosreport-testuser.12345-20170611105406/etc/my.cnf.d/server.cnf
[WRONG] Checking ^[ \t]*innodb_flush_log_at_trx_commit.*=.*1 is in ../sosreport-testuser.12345-20170611105406/etc/my.cnf.d/server.cnf
[WRONG] Checking ^[ \t]*innodb_lock_wait_timeout.*=.*50 is in ../sosreport-testuser.12345-20170611105406/etc/my.cnf.d/server.cnf
[WRONG] Checking ^[ \t]*innodb_max_purge_lag.*=.*10000 is in ../sosreport-testuser.12345-20170611105406/etc/my.cnf.d/server.cnf
[WRONG] Checking ^[ \t]*innodb_thread_concurrency.*=.*2 is in ../sosreport-testuser.12345-20170611105406/etc/my.cnf.d/server.cnf
[root@undercloud-0 citellus]# 
```

### Example of non-filtered messages

```
[root@undercloud-0 citellus]# ./citellus -f ../sosreport-testuser.12345-20170611105406
_________ .__  __         .__  .__                
\_   ___ \|__|/  |_  ____ |  | |  |  __ __  ______
/    \  \/|  \   __\/ __ \|  | |  | |  |  \/  ___/
\     \___|  ||  | \  ___/|  |_|  |_|  |  /\___ \ 
 \______  /__||__|  \___  >____/____/____//____  >
        \/              \/                     \/ 
SOSreport was created at Sun Jun 11 10:54:19 EDT 2017
Hostname: undercloud-0.redhat.local
Discovered node: osp-director
Version: Red Hat OpenStack Platform 8/Liberty
+-----------------------------------------------------------------------------+
| Kernel Module                                                               |
+--------------------------------------------+--------------------------------|
| PASS: 2         FAILED: 0      WARNING: 0  |                Result: PASSED  |
+-----------------------------------------------------------------------------+
[OK] Checking oom-killer is NOT in ../sosreport-testuser.12345-20170611105406/sos_commands/logs/journalctl_--no-pager_--boot
[OK] Checking soft lockup is NOT in ../sosreport-testuser.12345-20170611105406/sos_commands/logs/journalctl_--no-pager_--boot
+-----------------------------------------------------------------------------+
| Traceback Module                                                            |
+--------------------------------------------+--------------------------------|
| PASS: 10        FAILED: 1      WARNING: 4  |                Result: FAILED  |
+-----------------------------------------------------------------------------+
[OK] No match for word Traceback in ../sosreport-testuser.12345-20170611105406/var/log/ceilometer/agent-notification.log
[WARN] There are 1 occurences of word Traceback in ../sosreport-testuser.12345-20170611105406/var/log/ceilometer/alarm-evaluator.log
[OK] No match for word Traceback in ../sosreport-testuser.12345-20170611105406/var/log/ceilometer/alarm-notifier.log
[OK] No match for word Traceback in ../sosreport-testuser.12345-20170611105406/var/log/ceilometer/api.log
[OK] No match for word Traceback in ../sosreport-testuser.12345-20170611105406/var/log/ceilometer/ceilometer-dbsync.log
[WRONG] There are 92 occurences of word Traceback in ../sosreport-testuser.12345-20170611105406/var/log/ceilometer/central.log
[OK] No match for word Traceback in ../sosreport-testuser.12345-20170611105406/var/log/ceilometer/collector.log
[WARN] There are 9 occurences of word Traceback in ../sosreport-testuser.12345-20170611105406/var/log/glance/api.log
[OK] No match for word Traceback in ../sosreport-testuser.12345-20170611105406/var/log/glance/registry.log
[OK] No match for word Traceback in ../sosreport-testuser.12345-20170611105406/var/log/heat/heat-api-cfn.log
[OK] No match for word Traceback in ../sosreport-testuser.12345-20170611105406/var/log/heat/heat-engine.log
[OK] No match for word Traceback in ../sosreport-testuser.12345-20170611105406/var/log/keystone/keystone.log
[WARN] There are 2 occurences of word Traceback in ../sosreport-testuser.12345-20170611105406/var/log/neutron/dhcp-agent.log
[OK] No match for word Traceback in ../sosreport-testuser.12345-20170611105406/var/log/neutron/openvswitch-agent.log
[WARN] There are 6 occurences of word Traceback in ../sosreport-testuser.12345-20170611105406/var/log/nova/nova-api.log
+-----------------------------------------------------------------------------+
| Checking cronjob                                                            |
+--------------------------------------------+--------------------------------|
| PASS: 1         FAILED: 0      WARNING: 1  |                Result: WARNING |
+-----------------------------------------------------------------------------+
[WARN] Missing file ../sosreport-testuser.12345-20170611105406/var/spool/cron/keystone
[OK] Checking heat-manage purge_deleted is in ../sosreport-testuser.12345-20170611105406/var/spool/cron/heat
+-----------------------------------------------------------------------------+
| My Custom Module                                                            |
+--------------------------------------------+--------------------------------|
| PASS: 2         FAILED: 0      WARNING: 0  |                Result: PASSED  |
+-----------------------------------------------------------------------------+
[OK] Checking REDIRECT.*169.254.169.254 is in ../sosreport-testuser.12345-20170611105406/sos_commands/networking/iptables_-t_nat_-nvL
[OK] Checking neutron.*failed|openstack.*failed is NOT in ../sosreport-testuser.12345-20170611105406/sos_commands/systemd/systemctl_list-units_--all
+-----------------------------------------------------------------------------+
| Checking Hardware Requirements                                              |
+--------------------------------------------+--------------------------------|
| PASS: 4         FAILED: 1      WARNING: 0  |                Result: FAILED  |
+-----------------------------------------------------------------------------+
[OK] Memory is greater than or equal to 16GB
[OK] Checking vmx\|svm is in ../sosreport-testuser.12345-20170611105406/proc/cpuinfo
[WRONG] Undercloud requires minimum 8-core 64-bit x86 processor
[OK] A minimum of 40GB of available disk space
[OK] A minimum of 10GB of free disk space
+-----------------------------------------------------------------------------+
| Checking Tuning options                                                     |
+--------------------------------------------+--------------------------------|
| PASS: 4         FAILED: 6      WARNING: 0  |                Result: FAILED  |
+-----------------------------------------------------------------------------+
[OK] Checking ^[ \t]*max_resources_per_stack.*=.*-1 is in ../sosreport-testuser.12345-20170611105406/etc/heat/heat.conf
[OK] Checking ^[ \t]*num_engine_workers.*=.*4 is in ../sosreport-testuser.12345-20170611105406/etc/heat/heat.conf
[OK] Checking ^[ \t]*max_connections.*=.*4096 is in ../sosreport-testuser.12345-20170611105406/etc/my.cnf.d/server.cnf
[WRONG] Checking ^[ \t]*innodb_additional_mem_pool_size.*=.*20M is in ../sosreport-testuser.12345-20170611105406/etc/my.cnf.d/server.cnf
[WRONG] Checking ^[ \t]*innodb_buffer_pool_size.*=.*1000M is in ../sosreport-testuser.12345-20170611105406/etc/my.cnf.d/server.cnf
[WRONG] Checking ^[ \t]*innodb_flush_log_at_trx_commit.*=.*1 is in ../sosreport-testuser.12345-20170611105406/etc/my.cnf.d/server.cnf
[WRONG] Checking ^[ \t]*innodb_lock_wait_timeout.*=.*50 is in ../sosreport-testuser.12345-20170611105406/etc/my.cnf.d/server.cnf
[WRONG] Checking ^[ \t]*innodb_max_purge_lag.*=.*10000 is in ../sosreport-testuser.12345-20170611105406/etc/my.cnf.d/server.cnf
[WRONG] Checking ^[ \t]*innodb_thread_concurrency.*=.*2 is in ../sosreport-testuser.12345-20170611105406/etc/my.cnf.d/server.cnf
[OK] Checking ^[ \t]*max_concurrent_builds.*=.*5 is in ../sosreport-testuser.12345-20170611105406/etc/nova/nova.conf
[root@undercloud-0 citellus]# 
```
