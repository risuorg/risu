**Table of contents**

<!-- TOC depthFrom:1 insertAnchor:false orderedList:false -->

- [Introduction](#introduction)
- [How to add a new file to monitor](#how-to-add-a-new-file-to-monitor)

<!-- /TOC -->

## Introduction

This extension allows to define files that must be outputed to stderr as metadata source.

## How to add a new file to monitor

- Create a new text file in the folder (try recreating path or context in path) so include/exclude filters do also work

- Inside that file introduce same tags as other plugins:
  - bugzilla: URL of the bug containing info if any
  - long_name: Long name of the file
  - priority: how likely is this to be a big problem in the environment
  - description: Description of the file to monitor
  - path: Path to the file to check, if it contains RISU_ROOT it's for snapshot mode.
  - If text RISU_HYBRID is found, the file path is valid for both live and not live (use RISU_ROOT and it will be "" for live execution)
