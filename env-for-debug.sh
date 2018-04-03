#!/bin/bash
# Copyright (C) 2018 Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)

# description: Setup environment for manual debug of plugin
# This script tries to mimic what citellus.py does so it has some hardcoded defaults that must be kept in sync with Citellus
#


# Folder for citellus
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export CITELLUS_BASE=${DIR}/citellusclient/

# Error code definition
export RC_OKAY=10
export RC_FAILED=20
export RC_SKIPPED=30

# i18n for bash support
export LANG='en_US'
export TEXTDOMAIN='citellus'
export TEXTDOMAINDIR=${CITELLUS_BASE}/locale

# Root directory for sosreport
export CITELLUS_ROOT=.

# Force to run non-live
export CITELLUS_LIVE=0

# Load common functions
. ${CITELLUS_BASE}/common-functions.sh


echo -e "Citellus environment loaded, now you can run from current directory for sosreport root the plugin to debug via sh -x script\n\n"