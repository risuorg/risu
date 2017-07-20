# Introduction

Citellus is a program that should help faster identify common pitfails of OpenStack deployments from live system or any sort of snapshot of the filesystem.

Please if you have any idea on any improvements please do not hesitate to open an issue.

## Usage help

```
# ./citellus --help
_________ .__  __         .__  .__                
\_   ___ \|__|/  |_  ____ |  | |  |  __ __  ______
/    \  \/|  \   __\/ __ \|  | |  | |  |  \/  ___/
\     \___|  ||  | \  ___/|  |_|  |_|  |  /\___ \ 
 \______  /__||__|  \___  >____/____/____//____  >
        \/              \/                     \/ 

Usage: citellus [-hv] [--live] [DIRECTORY] [script folder] ... 
Run collection of tests either on fs snapshot or on live system and writes the result to standard output.

              -h                  display this help and exit
              --live              run script collections on live system
              DIRECTORY           run script collections on directory
              -v                  verbose mode.

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

## Writing checks

Citellus tests should conform to the following standards:

- The test script must be executable. Citellus will ignore tests for
  which it does not have execute permission.

- The test should return one of the following error codes to indicate
  the test result:

    - 0 - success
    - 1 - failure
    - 2 - skipped

A test may make use of the following standard environment variables:

- `$CITELLUS_ROOT` -- tests that parse files should locate them
  relative to this directory.  For example, if your script needs to
  examine `/etc/sysctl.conf`, it might have something like:

          if grep -q '^net.ipv4.ip_forward = 1' "${CITELLUS_ROOT}/etc/sysctl.conf"; then
              ...
          fi
- `$CITELLUS_LIVE` -- if `0`, tests are running against a filesystem
  snapshot of some sort.  Tests should not attempt to use commands
  that interrogate the system on which it is running.  If this
  variable is `1`, the tests are running on a live system.
