**Table of contents**

<!-- TOC depthFrom:1 insertAnchor:false orderedList:false -->

- [Introduction](#introduction)
- [How to add a new file to monitor](#how-to-add-a-new-file-to-monitor)

<!-- /TOC -->

## Introduction

This extension allows to define files that must be equal or different in a sosreport (across several of them)

This allows for example to check that pipeline-yaml for ceilometer is the same for all the environment but at the same time that each host has different iSCSI initiator name.

For doing so, this extension does find files named with 'filename.txt' in the possitve affinity or negative and reports back as different plugins.

Then the listplugins and runplugin functions do take that 'fake' plugin to be processed as it should (reporting md5sum on the file so then Magui can also process this affinity or not.

## How to add a new file to monitor

- Create a new text file in the folder (try recreating path or context in path) so include/exclude filters do also work

- Inside that file introduce same tags as other plugins:
  - bugzilla: URL of the bug containing info if any
  - long_name: Long name of the file
  - priority: how likely is this to be a big problem in the environment
  - description: Description of the file to monitor
  - path: Path to the file to check, if it contains RISU_ROOT it's for snapshot mode.
    - if path contains ',' it will accept CSV paths for different files and the plugin name will get appended the path of tile, same as description this allows to define 'bundles' of files.
  - If text RISU_HYBRID is found, the file path is valid for both live and not live (use RISU_ROOT and it will be "" for live execution)
