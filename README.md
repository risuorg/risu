# Introduction

Citellus is a program that should help faster identify common pitfails of OpenStack deployments from live system or any sort of snapshot of the filesystem.

Please if you have any idea on any improvements please do not hesitate to open an issue.

## Usage help

```
Usage: citellus [-hv] [--live] [DIRECTORY] [script folder] ... 
```

## Doing a live check example

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

## Doing a fs snapshot check example

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
