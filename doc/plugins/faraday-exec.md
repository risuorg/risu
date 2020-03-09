**Table of contents**

<!-- TOC depthFrom:1 insertAnchor:false orderedList:false -->

- [Introduction](#introduction)
- [How to add a new file to monitor](#how-to-add-a-new-file-to-monitor)
- [Execution](#execution)

<!-- /TOC -->

## Introduction

This extension allows to define files that must be equal or different in a sosreport (across several of them)

This allows for example to check that iptables rules is the same for all the environment.

For doing so, this extension does find files named with 'filename.sh' in the possitve affinity or negative and reports back as different plugins.

Then the listplugins and runplugin functions do take that 'fake' plugin to be processed as it should (reporting md5sum on the file so then Magui can also process this affinity or not.

## How to add a new file to monitor

- Create a new script in the folder (try recreating path or context in path) so include/exclude filters do also work

- Inside that file introduce same tags as other plugins:
  - bugzilla: URL of the bug containing info if any
  - long_name: Long name of the file
  - priority: how likely is this to be a big problem in the environment
  - description: Description of the file to monitor
  - path: Path to the file checked
  - Write required code for getting value that will be compared, for example md5sum after excluding comments (like in iptables example)

## Execution

During execution will run the plugin like 'metadata' plugins but use results later via datahook with magui plugins for faraday positive or negative.
