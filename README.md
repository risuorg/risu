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

Usage: citellus [-h] [-d DIRECTORY]...
Do stuff with sosreport and write the result to standard output.

              -h              display this help and exit
              -d sosreport-*  opens a sosreport directory for analysis
```

```bash
[root@undercloud-0 citellus]# ./citellus -d ../sosreport-testuser.12345-20170611031416
_________ .__  __         .__  .__                
\_   ___ \|__|/  |_  ____ |  | |  |  __ __  ______
/    \  \/|  \   __\/ __ \|  | |  | |  |  \/  ___/
\     \___|  ||  | \  ___/|  |_|  |_|  |  /\___ \ 
 \______  /__||__|  \___  >____/____/____//____  >
        \/              \/                     \/ 
SOSreport was created at Sun Jun 11 03:15:07 EDT 2017
Hostname: undercloud-0.redhat.local
Discovered node: osp-director
Version: Red Hat OpenStack Platform 8/Liberty

+--------------------------------------------+
|            Checking common ERRORS          |
+--------------------------------------------+
[OK] Checking "REDIRECT.*169.254.169.254" in iptables.
[OK] No failed openstack * neutron* services found in undercloud.
+--------------------------------------------+
|        Checking Hardware Requirements      |
+--------------------------------------------+
[OK] Memory is greater than or equal to 16GB
+--------------------------------------------+
|           Checking Tuning options          |
+--------------------------------------------+
[OK] Checking value max_resources_per_stack is set to -1 in ../sosreport-testuser.12345-20170611031416/etc/heat/heat.conf
[WRONG] Checking value num_engine_workers is set to 4 in ../sosreport-testuser.12345-20170611031416/etc/heat/heat.conf
[MISSING] Missing ../sosreport-testuser.12345-20170611031416/etc/my.cnf.d/server.cnf
[MISSING] Missing ../sosreport-testuser.12345-20170611031416/etc/my.cnf.d/server.cnf
[MISSING] Missing ../sosreport-testuser.12345-20170611031416/etc/my.cnf.d/server.cnf
[MISSING] Missing ../sosreport-testuser.12345-20170611031416/etc/my.cnf.d/server.cnf
[MISSING] Missing ../sosreport-testuser.12345-20170611031416/etc/my.cnf.d/server.cnf
[MISSING] Missing ../sosreport-testuser.12345-20170611031416/etc/my.cnf.d/server.cnf
[MISSING] Missing ../sosreport-testuser.12345-20170611031416/etc/my.cnf.d/server.cnf
[WRONG] Checking keystone-manage token_flush is in ../sosreport-testuser.12345-20170611031416/var/spool/cron/keystone
[OK] Checking heat-manage purge_deleted is in ../sosreport-testuser.12345-20170611031416/var/spool/cron/heat
[OK] Checking value max_concurrent_builds is set to 5 in ../sosreport-testuser.12345-20170611031416/etc/nova/nova.conf

```
