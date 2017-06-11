## Introduction

Citellus is a program that should help faster identify common pitfails of OpenStack deployments from sosreports.

### Usage

```bash
[root@undercloud-0 citellus]# ./citellus -h 
_________ .__  __         .__  .__                
\_   ___ \|__|/  |_  ____ |  | |  |  __ __  ______
/    \  \/|  \   __\/ __ \|  | |  | |  |  \/  ___/
\     \___|  ||  | \  ___/|  |_|  |_|  |  /\___ \ 
 \______  /__||__|  \___  >____/____/____//____  >
        \/              \/                     \/ 

Usage: citellus [-hv] [-f DIRECTORY]...
Do stuff with sosreport and write the result to standard output.

              -h              display this help and exit
              -f sosreport-*  opens a sosreport directory for analysis
              -v              verbose mode.
[root@undercloud-0 citellus]# 
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
+--------------------------------------------+
|            Checking common ERRORS          |
+--------------------------------------------+
[OK] Checking REDIRECT.*169.254.169.254 is in ../sosreport-testuser.12345-20170611105406/sos_commands/networking/iptables_-t_nat_-nvL
[OK] Checking neutron.*failed|openstack.*failed is NOT in ../sosreport-testuser.12345-20170611105406/sos_commands/systemd/systemctl_list-units_--all
+--------------------------------------------+
|        Checking Hardware Requirements      |
+--------------------------------------------+
[OK] Memory is greater than or equal to 16GB
[OK] Checking vmx\|svm is in ../sosreport-testuser.12345-20170611105406/proc/cpuinfo
[WRONG] Undercloud requires minimum 8-core 64-bit x86 processor
[OK] A minimum of 40GB of available disk space
[OK] A minimum of 10GB of free disk space
+--------------------------------------------+
|           Checking Tuning options          |
+--------------------------------------------+
[OK] Checking max_resources_per_stack.*=.*-1 is in ../sosreport-testuser.12345-20170611105406/etc/heat/heat.conf
[OK] Checking num_engine_workers.*=.*4 is in ../sosreport-testuser.12345-20170611105406/etc/heat/heat.conf
[OK] Checking max_connections.*=.*4096 is in ../sosreport-testuser.12345-20170611105406/etc/my.cnf.d/server.cnf
[WRONG] Checking innodb_additional_mem_pool_size.*=.*20M is in ../sosreport-testuser.12345-20170611105406/etc/my.cnf.d/server.cnf
[WRONG] Checking innodb_buffer_pool_size.*=.*1000M is in ../sosreport-testuser.12345-20170611105406/etc/my.cnf.d/server.cnf
[WRONG] Checking innodb_flush_log_at_trx_commit.*=.*1 is in ../sosreport-testuser.12345-20170611105406/etc/my.cnf.d/server.cnf
[WRONG] Checking innodb_lock_wait_timeout.*=.*50 is in ../sosreport-testuser.12345-20170611105406/etc/my.cnf.d/server.cnf
[WRONG] Checking innodb_max_purge_lag.*=.*10000 is in ../sosreport-testuser.12345-20170611105406/etc/my.cnf.d/server.cnf
[WRONG] Checking innodb_thread_concurrency.*=.*2 is in ../sosreport-testuser.12345-20170611105406/etc/my.cnf.d/server.cnf
[MISSING] Missing ../sosreport-testuser.12345-20170611105406/var/spool/cron/keystone
[OK] Checking heat-manage purge_deleted is in ../sosreport-testuser.12345-20170611105406/var/spool/cron/heat
[OK] Checking max_concurrent_builds.*=.*5 is in ../sosreport-testuser.12345-20170611105406/etc/nova/nova.conf

```
