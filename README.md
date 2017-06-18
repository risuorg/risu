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

Usage: citellus [-hv] [-d warn,good,bad] [-p openstack] [-f DIRECTORY]...
Do stuff with sosreport and write the result to standard output.

              -h                  display this help and exit
              -f sosreport-*      opens a sosreport directory for analysis
              -d warn,good,bad    will display only filtered messages
              -p openstack        select plugin to run from plugins
              -v                  verbose mode.

```

### Folder structure

This will try to explain how the scripts are executed, it all depends on the folder structure right now.

```

[root@undercloud-0 citellus]# tree
.
|-- citellus
|-- load_functions
|-- plugins
|   `-- openstack
|       |-- generic

<-------- These scripts are executed against all hosts. --------/>

|       |   |-- all
|       |   |   |-- kernel.sh
|       |   |   |-- selinux.sh
|       |   |   `-- traceback.sh

<-------- These scripts are executed against all controller nodes. --------/>

|       |   |-- controller
|       |   |   |-- cluster.sh
|       |   |   |-- cronjob.sh
|       |   |   |-- custom.sh
|       |   |   |-- httpd.sh
|       |   |   `-- rabbitmq.sh

<-------- These scripts are executed against all director nodes. --------/>
  
|       |   `-- director
|       |       `-- custom.sh

<-------- The scripts in this directory are only checked against specific version --------/>

|       |-- kilo

<-------- These scripts are executed specific version and specific node type. --------/>

|       |   |-- compute
|       |   |   `-- hwreq.sh
|       |   |-- controller
|       |   |   `-- hwreq.sh
|       |   |-- director
|       |   `-- generic
|       |-- liberty
|       |   |-- compute
|       |   |   `-- hwreq.sh
|       |   |-- controller
|       |   |   `-- hwreq.sh
|       |   |-- director
|       |   |   |-- cronjob.sh
|       |   |   |-- hwreq.sh
|       |   |   `-- tuning.sh
|       |   `-- generic
|       |-- mitaka
|       |   |-- compute
|       |   |   `-- hwreq.sh
|       |   |-- controller
|       |   |   `-- hwreq.sh
|       |   |-- director
|       |   |   |-- cronjob.sh
|       |   |   |-- hwreq.sh
|       |   |   `-- tuning.sh
|       |   `-- generic
|       |-- newton
|       |   |-- compute
|       |   |   `-- hwreq.sh
|       |   |-- controller
|       |   |   `-- hwreq.sh
|       |   |-- director
|       |   |   |-- cronjob.sh
|       |   |   |-- hwreq.sh
|       |   |   `-- tuning.sh
|       |   `-- generic
|       |-- ocata
|       |   |-- compute
|       |   |   `-- hwreq.sh
|       |   |-- controller
|       |   |   `-- hwreq.sh
|       |   |-- director
|       |   |   |-- cronjob.sh
|       |   |   |-- hwreq.sh
|       |   |   `-- tuning.sh
|       |   `-- generic
|       `-- pike
|           |-- compute
|           |-- controller
|           |-- director
|           `-- generic
`-- README.md

36 directories, 34 files
```
