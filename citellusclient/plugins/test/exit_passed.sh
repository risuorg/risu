#!/bin/sh

echo $0 something on stdout
echo $0 something on stderr >&2
exit ${RC_OKAY}
