#!/bin/bash

trace_name=$1

begin_flag="negs   w0, w1, ASR #4"
end_flag="negs   w1, w0, ASR #4"

[ -f $trace_name ] || exit
begin_line=`grep "$begin_flag" -wn $trace_name | cut -d ":" -f 1`
end_line=`grep "$end_flag" -wn $trace_name | cut -d ":" -f 1`
begin_line=$(($begin_line - 8))
end_line=$(($end_line + 8))
line_cnt=$(($end_line - $begin_line))

echo "Process $line_cnt lines $begin_line:$end_line  in trace $trace_name"

trace_tmp=$trace_name.tmp
sed "1,${begin_line}d" $trace_name > $trace_tmp
head -n $line_cnt $trace_tmp | grep Memory -v | cut -d ":" -f 4     | cut -d "/" -f 1 > ${trace_name}-i.txt
head -n $line_cnt $trace_tmp | grep Memory -v | cut -d ":" -f 4,5   | cut -d "/" -f 1 > ${trace_name}-id.txt
head -n $line_cnt $trace_tmp | grep Memory -v | cut -d ":" -f 4,5,6 | cut -d "/" -f 1 > ${trace_name}-ida.txt
ls -l ${trace_name}-i*.txt

