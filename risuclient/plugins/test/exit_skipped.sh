#!/bin/sh

# Copyright (C) 2017 Lars Kellogg-Stedman <lars@redhat.com>
# Copyright (C) 2018 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

echo $0 something on stdout
echo $0 something on stderr >&2
exit ${RC_SKIPPED}
