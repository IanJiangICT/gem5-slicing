#!/bin/bash

trace_name=$1
[ -f $trace_name ] || exit
cat $trace_name | grep @ | grep -v "Memory" > $trace_name.tmp
cat $trace_name.tmp | cut -d ":"  -f 3 > $trace_name-pos.txt
cat $trace_name.tmp | cut -d ":"  -f 4     | cut -d "/" -f 1 > $trace_name-i.txt
cat $trace_name.tmp | cut -d ":"  -f 4,5,6 | cut -d "/" -f 1 > $trace_name-ida.txt
cat $trace_name-ida.txt | sed 's/A=.*//' > $trace_name-id.txt

