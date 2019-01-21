#!/bin/sh
REQ=$(cat)
X=$(echo $REQ | cut -d';' -f1)
Y=$(echo $REQ | cut -d';' -f2)
echo "Speed: X=$X Y=$Y, Req: $REQ"
echo -n "$X;$Y;$(date +%s%3N)">/tmp/wallie/speed
