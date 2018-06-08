#!/bin/sh

# Modifications (2018) by Pablo Iranzo Gómez <Pablo.Iranzo@redhat.com>
# Modifications (2017) by Lars Kellogg-Stedman <lars@redhat.com>

echo $0 something on stdout
echo $0 something on stderr >&2
exit ${RC_FAILED}

