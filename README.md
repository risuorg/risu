# Introduction

Citellus is a program that should help faster identify common pitfails of OpenStack deployments from live system or any sort of snapshot of the filesystem.

Please if you have any idea on any improvements please do not hesitate to open an issue.

## Usage help
We are developing framework in python, the bash framework has been deprecated. Python framework is the only supported framework.

```
usage: citellus.py [arguments] [-h] [-l] [-v] [-d {info,debug,warn,critical}]
```

## Doing a live check example

This is an example of execution of Citellus using all system and pacemaker tests collections.
```
# ./citellus.py -l plugins/system/ plugins/pacemaker/
_________ .__  __         .__  .__                
\_   ___ \|__|/  |_  ____ |  | |  |  __ __  ______
/    \  \/|  \   __\/ __ \|  | |  | |  |  \/  ___/
\     \___|  ||  | \  ___/|  |_|  |_|  |  /\___ \ 
 \______  /__||__|  \___  >____/____/____//____  >
        \/              \/                     \/ 
found #12 tests at plugins/system/, plugins/pacemaker/
mode: live
# plugins/pacemaker/fence_device.sh: skipped
# plugins/pacemaker/nodes_number.sh: skipped
# plugins/pacemaker/stonith_enabled.sh: skipped
# plugins/pacemaker/stopped_resources.sh: skipped
# plugins/system/baremetal.sh: failed
    KVM
    
# plugins/system/disk_usage.sh: okay
# plugins/system/hardware_virtualization.sh: okay
# plugins/system/kernel_panic.sh: okay
# plugins/system/rh-release.sh: okay
# plugins/system/selinux_config.sh: okay
# plugins/system/selinux_runtime.sh: okay
```

And exactly the same execution against the fs snapshot, with one difference, omitting the ```-l``` and instead specifying the directory with fs snapshot.

## Doing a fs snapshot check example

This is an example of execution of Citellus using ```plugins/pacemaker``` and ```plugins/system``` collections against fs snapshot ```sosreport-controller-1.localdomain-20170705201135```
```
# ./citellus /root/sosreport-controller-1.localdomain-20170705201135/ plugins/system/ plugins/pacemaker/
_________ .__  __         .__  .__                
\_   ___ \|__|/  |_  ____ |  | |  |  __ __  ______
/    \  \/|  \   __\/ __ \|  | |  | |  |  \/  ___/
\     \___|  ||  | \  ___/|  |_|  |_|  |  /\___ \ 
 \______  /__||__|  \___  >____/____/____//____  >
        \/              \/                     \/ 
citellus: found 12 tests
mode: fs snapshot /root/sosreport-controller-1.localdomain-20170705201135
# plugins/pacemaker/failed_actions.sh: okay 
# plugins/pacemaker/fence_device.sh: skipped 
# plugins/pacemaker/nodes_number.sh: okay 
# plugins/pacemaker/stonith_enabled.sh: failed 

# plugins/pacemaker/stopped_resources.sh: okay 
# plugins/system/baremetal.sh: failed 
    KVM

# plugins/system/disk_usage.sh: okay 
# plugins/system/hardware_virtualization.sh: okay 
# plugins/system/kernel_panic.sh: skipped 
# plugins/system/rh-release.sh: okay 
# plugins/system/selinux_config.sh: okay 
# plugins/system/selinux_runtime.sh: okay 
```
