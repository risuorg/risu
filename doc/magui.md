**Table of contents**

<!-- TOC depthFrom:1 insertAnchor:false orderedList:false -->

- [Introduction](#introduction)
- [Highlights](#highlights)
- [Installation](#installation)
- [Usage help](#usage-help)
  - [Running a check](#running-a-check)
    - [Running a check against remote hosts](#running-a-check-against-remote-hosts)
    - [Autogrouping](#autogrouping)
- [Plugin development for Magui](#plugin-development-for-magui)

<!-- /TOC -->

## Introduction

Magui is a wrapper that calls functions from the Python library of Risu [risu.md](risu.md).

Some problems are not detected only one one node, but are made by the aggregation of data across them, for example:

- ntp sync
- galera replication status
- etc
- RHEL release differences

Magui aims to use Risu for gathering the data and later, write plugins to analyze that information.

## Highlights

- Reuse saved risu.json to speed up analisys on several files, retrigger if inconsistencies

- Plugins use uuid to identify plugin properly and act on them.

- Allows to get data from remote hosts with ansible-playbook

- Autogrouping: based on metadata plugin, runs comparisons against sets of host roles, hostnames, etc for better spotting issues across systems.

- Web interface using `risu.html?json=magui.json`

Check latest changes on [changelog](changelog.md)

## Installation

- Just clone the git repository and execute it from there 'or'
- use 'pipsi' or create a python virtual env to install package 'risu'
  ```sh
  # pipsi install risu
  Already using interpreter /usr/bin/python3
  Using base prefix '/usr'
  New python executable in /home/iranzo/.local/venvs/risu/bin/python3
  Also creating executable in /home/iranzo/.local/venvs/risu/bin/python
  Installing setuptools, pip, wheel...done.
  Collecting risu
  Installing collected packages: risu
  Successfully installed risu-0.1.0.dev1072
    Linked script /home/iranzo/.local/bin/risu.py
    Linked script /home/iranzo/.local/bin/magui.py
  Done.
  ```
  - Pipsi will take care of installing a virtual environment and link to binary folder so you can call risu.py or magui.py directly
  - Remember that pypi package might not contain all the latests plugins features as the github repo one.
- Container:
  - Use our automatically built container in docker hub:
    - `docker run --user=$(id -u) --rm -v $PATHTOSOSREPORT:/data:Z risu/risu:latest /data --entrypoint="magui.py"`
  - or build your own using the included `Dockerfile` in the git checkout.
    - `docker build . -f Dockerfile.centos7-atomic -t risu:latest` # (from git checkout, then note image id)
    - `docker run --user=$(id -u) --rm -v $PATHTOSOSREPORT:/data:Z risu:latest /data --entrypoint="magui.py"`
  - Notes about using docker:
    - Docker passes as volume the path specified under /data so we do use that parameter with risu for running the tests.
    - The default user id within the container is 10001 and the commands or sosreport permissions doesn't allow that user to gather all the information, so the container is required to run as the current user.

## Usage help

Plugins for Magui are to be written in Python, check next section for details.

````
usage: magui.py [arguments] [-h] [-d {INFO,DEBUG,WARNING,ERROR,CRITICAL}]
                            [--list-plugins] [--description] [-m MPATH]
                            [--output FILENAME] [--run] [--hosts hosts]
                            [--max-hosts max-hosts] [-q] [-i SUBSTRING]
                            [-x SUBSTRING] [-p [0-1000]] [-mf MFILTER]
                            [--anon] [--lang LANG] [--call-home serveruri]
                            [sosreports [sosreports ...]]

Processes several generic archives/sosreports scripts in a uniform way, to
interpret status that depend on several systems data

positional arguments:
  sosreports

optional arguments:
  -h, --help            show this help message and exit
  -d {INFO,DEBUG,WARNING,ERROR,CRITICAL}, --loglevel {INFO,DEBUG,WARNING,ERROR,CRITICAL}
                        Set log level
  --list-plugins        Print a list of discovered Magui plugins and exit
  --description         With list-plugins, also outputs plugin description
  -m MPATH, --mpath MPATH
                        Set path for Magui plugin location if not default
  --output FILENAME, -o FILENAME
                        Write results to JSON file FILENAME
  --run, -r             Force run of risu instead of reading existing
                        'risu.json'
  --hosts hosts         Gather data via ansible from remote hosts to process.
  --max-hosts max-hosts
                        Define the number of maximum symultaneus hosts checks

Filtering options:
  -q, --quiet           Enable quiet mode
  -i SUBSTRING, --include SUBSTRING
                        Only include plugins that contain substring
  -x SUBSTRING, --exclude SUBSTRING
                        Exclude plugins that contain substring
  -p [0-1000], --prio [0-1000]
                        Only include plugins are equal or above specified prio
  -mf MFILTER, --mfilter MFILTER
                        Only include Magui plugins that contains in full path
                        that substring
  --anon                Anonymize output
  --lang LANG           Define locale to use
  --call-home serveruri
                        Server URI to HTTP-post upload generated risu.json
                        for metrics```

Magui can be executed using the risu docker image as well, by modifying
the entrypoint:

In a directory structure as:

````

/path/to/my/sosreports/
├── sosreport-overcloud-controller-0
├── sosreport-overcloud-controller-1
└── sosreport-overcloud-controller-2

````

```docker run --user=$(id -u) --rm --entrypoint="magui.py" -v /path/to/my/sosreports/:/data:Z risu:latest -q /data/sosreport-overcloud-controller-0/ /data/sosreport-overcloud-controller-1/ /data/sosreport-overcloud-controller-2/```

### Running a check

This is an example of execution of Magui against a set of sosreports with `seqno` plugin of Risu enabled.

~~~sh
#magui.py * -i seqno # (filtering for ‘seqno’ plugins.
{'/home/remote/piranzo/risu/risu/plugins/openstack/mysql/seqno.sh': {'ctrl0.localdomain': {'err': '08a94e67-bae0-11e6-8239-9a6188749d23:36117633\n',
                                                                                                   'out': '',
                                                                                                   'rc': 0},
                                                                             'ctrl1.localdomain': {'err': '08a94e67-bae0-11e6-8239-9a6188749d23:36117633\n',
                                                                                                   'out': '',
                                                                                                   'rc': 0},
                                                                             'ctrl2.localdomain': {'err': '08a94e67-bae0-11e6-8239-9a6188749d23:36117633\n',
                                                                                                   'out': '',
                                                                                                   'rc': 0}}}

On this example, UUID and SEQNO is shown for each controller.
~~~

#### Running a check against remote hosts

~~~sh
# Prepare host list in ansible-style
echo "host1" > hosts
echo "host2" >> hostsfile

# Run magui against them
./magui.py --hosts hostsfile
~~~

#### Autogrouping

[![asciicast](https://asciinema.org/a/170429.png)](https://asciinema.org/a/170429)

Magui does check `metadata` for finding host roles or hostnames that should be checked together and generates additional json files for them.


## Plugin development for Magui

Please do check [plugin development](development/magui-plugin-development.md) for more details.

Please if you have any idea on any improvements please do not hesitate to open an issue or submit your contributions.
````
