## Changelog hilights

Checkout the 'blog' section of <https://citellus.org/blog/category/blog/>

This file will contain a manually mantained log of hilights between versions, it's not a very extensive detail, but some of the bigger changes/ideas will be added here.

## 2018-04-17
- Now Faraday results should be splitted into separate 'fake' plugins to easily spot the status.
- Some code optimizations to remove duplicate and or old code.

## 2018-03-25
- Implement `--find` to citellus so that it can grep across a folder set for checking historic data for tests.

## 2018-03-18
- Magui autogrouping support, generating files for each comparison set like osp roles, same hostname, etc. It's based on metadata plugins generated.
    - Skip reexecution if a specified sosreport set was already analyzed.

## 2018-03-02
- Implemented 'faraday-exec' plugin to generate fake plugins that run and output metadata that later is faked via a datahook to be compared via magui plugins.
- Implemented automatic pypi.org package generation for each master merge that allows to run citellus installed via 'pip' or 'pipsi'.

## 2018-02-17
- Implemented 'profiles' data hook
    - Allow to define a text file with include/exclude filter and description that grabs data from the obtained results and shows in one place all return codes and error messages received
    - This will allow to define 'healthchecks' based on other plugins output and generate them dinamycall.
    - As it is done as if another plugin was executed, same Web UI interface is available for checking results.

## 2018-02-11
Several changes introduced recently:
- New plugins :)
- When running rerun, improved some of the logic to also copy over www so that it matches the version of the json file.
- Improved rerun, to only get results for missing plugins (unless forcerun used)
- Faraday can now accept bundle of files CSV in the list of files, it will mangle the extension reported name and description to match the file iterated.
    - This allows one file to act over several FS files (for example, `policy.json` for several services).
- UT's
    - Some other UT tweaks to ensure plugins report no data to stdout, and ability to drop bunch of jsons to run that UT over them.
    - We moved data to be a dictionary (instead of array of dictionaries), to better and faster filter on included plugins and others that are dependant on data generated (like Magui ones).
    - UT to check for tests that were doing 'echo $RC_' instead of 'exit $RC_'
- Citellus www
    - Now uses the generated 'name' for plugins so we can tune it from the framework side.
    - Also, auto switches to `magui.json` when no `citellus.json` exists, or shows a dropdown to select which one to show.



## 2018-01-27
- DevConf.cz 2018 [Detect pitfalls of osp deployments with citellus](https://devconfcz2018.sched.com/event/DJXG/detect-pitfalls-of-osp-deployments-with-citellus)
    - Recording at <https://www.youtube.com/watch?v=SDzzqrUdn5A>

## 2018-01-24
- Faraday extension
    - Some files must be equal or different across sosreports, actually we do have `release` and `ceilometer-yaml` one that rely on this, but this is hard to mantain as each new file will require a new plugin for Citellus plus a new plugin for Magui.

    - In order to simplify this a new extension has been created so adding a new file to monitor no longer requires new plugins for `citellus` or `magui` but just creating a text file with some data within as documented on `citellusclient/plugins/faraday/README.md`

## 2018-01-22
- Changed the way we work with sosreports for Citellus and Magui:
    - Now all plugins are always executed and filters do act on the output only.
    - If the folder is writable, citellus will write `citellus.json` to sosreport folder.
    - If there's an existing `citellus.json` it will be loaded from disk and run skipped unless there are new plugins that require execution. Forcing execution can be indicated with parameter `-r` to both Magui and Citellus.

## 2018-01-16

### Citellus
- New functions for bash scripts!
    - We've created lot of functions to check different things:
        - installed rpm 
        - rpm over specific version
        - compare dates over X days
        - regexp in file
        - etc..
    - Functions do allow to do quicker plugin development.
- save/restore options so they can be loaded automatically for each execution
    - Think of enabled filters, excluded, etc
- metadata added for plugins and returned as dictionary
- plugin has a unique ID for all installations based on plugin relative path and plugin name
    - We do use that ID in magui to select the plugin data we'll be acting on
- plugin priority!
    - Plugins are assigned a number between 0 and 1000 that represents how likely it's going to affect your environment, and you can filter also on it with `--prio`
- extended via 'extensions' to provide support for other plugins
    - moved prior plugins to be `core` extension
    - ansible playbook support via `ansible-playbook` command
    - metadata plugins that just generate metadata (hostname, date for sosreport, etc)
- Web Interface!!
    - [David Valee Delisle](https://valleedelisle.com/) did a great job on preparing an html that loads citellus.json and shows it graphically.
    - Thanks to his work, we did extended some other features like priority, categories, etc that are calculated via citellus and consumed via citellus-www.
    - Interface can also load `magui.json` (with `?json=magui.json`) and show it's output.
    - We did extend citellus to take `--web` to automatically create the json named `citellus.json` on the folder specified with `-o` and copy the `citellus.html` file there. So if you provide sosreports over http, you can point to citellus.html to see graphical status! (check latest image at citellus website as [www.png](https://github.com/citellusorg/citellus/raw/master/doc/images/www.png) )
- Increased plugin count!
    - Now we do have more than 119 across different categories
    - A new plugin in python `reboot.py` that checks for unexpected reboots
    - Spectre/Meltdown security checks!

### Magui
- If there's an existing `citellus.json` magui does load it to speed it up process across multiple sosreports.
- Magui can also use `ansible-playbook` to copy citellus program to remote host and run there the command, and bring back the generated `citellus.json` so you can quickly run citellus across several hosts without having to manually perform operations or generate sosreports.
- Moved prior data to two plugins:
    - `citellus-outputs`
        - Citellus plugins output arranged by plugin and sosreport
    - `citellus-metadata`
        - Outputs metadata gathered by `metadata` plugins in citellus arranged by plugin and sosreport
- First plugins that compare data received from citellus on global level
    - Plugins are written in python and use each plugin `id` to just work on the data they know how to process
    - `pipeline-yaml`
        - Checks if pipeline.yaml and warns if is different across hosts
    - `seqno`
        - Checks latest galera seqno on hosts
    - `release`
        - Reports RHEL release across hosts and warns if is different across hosts
- Enable `quiet` mode on the data received from citellus as well as local plugins, so only outputs with ERROR or different output on sosreports is shown, even on magui plugins.
