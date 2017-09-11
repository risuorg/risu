#!/bin/bash
# encoding: utf-8
#
# Description: Common functions/values
#
# Copyright (C) 2017  Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)
#


# Update in citellus.py if changed

[ -z  $RC_OKAY ] && export RC_OKAY=10
[ -z  $RC_FAILED ] && export RC_FAILED=20
[ -z  $RC_SKIPPED ] && export RC_SKIPPED=30

