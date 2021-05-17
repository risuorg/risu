#!/bin/bash
# Copyright (C) 2018, 2020, 2021 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

# description: Setup environment for manual debug of plugin
# This script tries to mimic what risu.py does so it has some hardcoded defaults that must be kept in sync with Risu
#

# Folder for risu
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export RISU_BASE=${DIR}/risuclient/
export CITELLUS_BASE=${RISU_BASE}

# Error code definition
export RC_OKAY=10
export RC_FAILED=20
export RC_SKIPPED=30
export RC_INFO=40

# i18n for bash support
export LANG='en_US'
export TEXTDOMAIN='risu'
export TEXTDOMAINDIR=${RISU_BASE}/locale

# Root directory for sosreport
export RISU_ROOT=.
export CITELLUS_ROOT=${RISU_ROOT}

# Force to run non-live
export RISU_LIVE=0
export CITELLUS_LIVE=${RISU_LIVE}

# Load common functions
. ${RISU_BASE}/common-functions.sh

echo -e "Risu environment loaded, now you can run from current directory for sosreport root the plugin to debug via sh -x script\n\n"
