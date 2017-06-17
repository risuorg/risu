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
