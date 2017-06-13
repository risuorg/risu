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

Usage: citellus [-hv] [-d warn,good,bad] [-f DIRECTORY]...
Do stuff with sosreport and write the result to standard output.

              -h                  display this help and exit
              -f sosreport-*      opens a sosreport directory for analysis
              -d warn,good,bad    will display only filtered messages
              -v                  verbose mode.
[root@undercloud-0 citellus]# 
```
