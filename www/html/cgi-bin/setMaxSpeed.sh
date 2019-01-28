#!/bin/sh
/usr/sbin/i2cset -y 1 0x35 0x00 $QUERY_STRING
/usr/sbin/i2cset -y 1 0x35 0x00 $QUERY_STRING
/usr/sbin/i2cget -y 1 0x35
