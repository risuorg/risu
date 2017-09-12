#!/bin/sh

: ${REMOTE_PING_TARGET:=8.8.8.8}

if [ ! "x$CITELLUS_LIVE" = "x1" ]; then 
  echo "works on live-system only" >&2
  RC=$RC_SKIPPED
fi

gw=$(ip route | awk '$1 == "default" {print $3}')
echo "default gateway is: $gw" >&2

if ! ping -c1 $gw; then
    echo "default gateway is unreachable" >&2
    RC=$RC_FAILED
else
    echo "default gateway is reachable" >&2
    RC=$RC_OKAY
fi

if ! ping -c1 $REMOTE_PING_TARGET; then
    echo "remote target @ $REMOTE_PING_TARGET is unreachable" >&2
    RC=$RC_FAILED
else
    echo "remote target @ $REMOTE_PING_TARGET is reachable" >&2
    RC=$RC_OKAY
fi

exit $RC
