# Introduction

Citellus is a program that should help faster identify common pitfails of OpenStack deployments from live system or any sort of snapshot of the filesystem.

Please if you have any idea on any improvements please do not hesitate to open an issue.

## Usage help
There are currently two frameworks developed, one is in python and another in bash. We are still tuning the python framework and we will move to only supported python framework in the future.

**Python:**
```
usage: citellus.py [arguments] [-h] [-l] [-v] [-d {info,debug,warn,critical}]
```

**Bash:**
```
Usage: citellus [-hv] [--live] [DIRECTORY] [script folder] ... 
```

## Doing a live check example

This is an example of executing the **Bash** framework using ```plugins/pacemaker``` collections against live system.
```
# ./citellus --live plugins/pacemaker/
_________ .__  __         .__  .__                
\_   ___ \|__|/  |_  ____ |  | |  |  __ __  ______
/    \  \/|  \   __\/ __ \|  | |  | |  |  \/  ___/
\     \___|  ||  | \  ___/|  |_|  |_|  |  /\___ \ 
 \______  /__||__|  \___  >____/____/____//____  >
        \/              \/                     \/ 
citellus: found 3 tests
mode: live
# plugins/pacemaker/fence_device.sh: skipped 
# plugins/pacemaker/nodes_number.sh: skipped 
# plugins/pacemaker/stonith_enabled.sh: skipped 
```
This is an example of executing the **Python** framework using all collections against live system.
```
# ./citellus.py -l
_________ .__  __         .__  .__                
\_   ___ \|__|/  |_  ____ |  | |  |  __ __  ______
/    \  \/|  \   __\/ __ \|  | |  | |  |  \/  ___/
\     \___|  ||  | \  ___/|  |_|  |_|  |  /\___ \ 
 \______  /__||__|  \___  >____/____/____//____  >
        \/              \/                     \/ 
found #20 tests at /root/citellus/plugins
mode: live
# /root/citellus/plugins/openstack/mysql_keystone_tokendb.sh: okay
# /root/citellus/plugins/openstack/crontab_heat_stack-purge.sh: okay
# /root/citellus/plugins/openstack/hardware_memory_recommendations.sh: okay
# /root/citellus/plugins/system/kernel_panic.sh: okay
# /root/citellus/plugins/system/disk_usage.sh: okay
# /root/citellus/plugins/system/selinux_runtime.sh: okay
# /root/citellus/plugins/system/selinux_config.sh: okay
# /root/citellus/plugins/system/baremetal.sh: failed
KVM
(snip)
```

## Doing a fs snapshot check example
This is an example of executing the **Bash** framework using ```plugins/pacemaker``` and ```plugins/system``` collections against fs snapshot ```/sosreport-controller-1.localdomain-20170705201135/```
```
# ./citellus /root/sosreport-controller-1.localdomain-20170705201135/ plugins/system/ plugins/pacemaker/
_________ .__  __         .__  .__                
\_   ___ \|__|/  |_  ____ |  | |  |  __ __  ______
/    \  \/|  \   __\/ __ \|  | |  | |  |  \/  ___/
\     \___|  ||  | \  ___/|  |_|  |_|  |  /\___ \ 
 \______  /__||__|  \___  >____/____/____//____  >
        \/              \/                     \/ 
citellus: found 4 tests
mode: fs snapshot /root/sosreport-controller-1.localdomain-20170705201135/
# plugins/pacemaker/fence_device.sh: skipped 
# plugins/pacemaker/nodes_number.sh: okay 
# plugins/pacemaker/stonith_enabled.sh: failed 
# plugins/system/kernel_panic.sh: skipped 
    file /sos_commands/logs/journalctl_--no-pager_--boot not found.
```
This is an example of executing the **Python** framework using all collections against fs snapshot ```/sosreport-compute-0.localdomain-20170717184033/```

```
# ./citellus.py /root/sosreport-compute-0.localdomain-20170717184033/
_________ .__  __         .__  .__                
\_   ___ \|__|/  |_  ____ |  | |  |  __ __  ______
/    \  \/|  \   __\/ __ \|  | |  | |  |  \/  ___/
\     \___|  ||  | \  ___/|  |_|  |_|  |  /\___ \ 
 \______  /__||__|  \___  >____/____/____//____  >
        \/              \/                     \/ 
found #20 tests at /root/citellus/plugins
mode: fs snapshot /root/sosreport-compute-0.localdomain-20170717184033/
# /root/citellus/plugins/openstack/mysql_keystone_tokendb.sh: skipped
# /root/citellus/plugins/openstack/keystone_cleanup_last-run.sh: skipped
# /root/citellus/plugins/openstack/crontab_heat_stack-purge.sh: skipped
# /root/citellus/plugins/openstack/version.sh: okay
# /root/citellus/plugins/system/kernel_panic.sh: skipped
(snip)
```
