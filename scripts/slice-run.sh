#!/bin/bash

scripts_path=$(cd "$(dirname $0)"; pwd)
source $scripts_path/config.sh

target_platform="spike"

if [ $# -gt 0 ]; then
	slice_elf=$1
else
	echo "Usage:"
	echo "  slice-run.sh slice.elf [target-platform]"
	echo "Example:"
	echo "  slice-run.sh slice.elf spike"
	exit 1
fi
if [ $# -gt 1 ]; then
	target_platform=$2
fi

if [ ! -f $slice_elf ]; then
	echo "Error: $slice_elf not found"
	exit 2
fi

# Instruction count of 3 parts:
inst_cnt_boot=0 	# Boot code depends on platform
inst_cnt_init=0 	# Slice initiation
inst_cnt_slice=0 	# Slice body
inst_cnt_total=0
if [ -z $SIMPOINT_INTERVAL ]; then
	inst_cnt_slice=1000
else
	inst_cnt_slice=$SIMPOINT_INTERVAL
fi
OBJDUMP=$GNU_PREFIX-objdump
$OBJDUMP -D $slice_elf > $slice_elf.S
if [ ! $? -eq 0 ]; then
	echo "Error: Failed to objdump $slice_elf"
	exit 1
fi
line_num_entry=`grep -n \<simpoint_entry\>\: $slice_elf.S | cut -d ":" -f 1`
inst_cnt_init=`tail -n +$line_num_entry $slice_elf.S | grep -n "^$" | head -n 1 | cut -d ":" -f 1`
inst_cnt_init=$((inst_cnt_init-2))

if [ "$target_platform" == "spike" ]; then
	which $SPIKE_BIN >> /dev/null
	if [ ! $? -eq 0 ]; then
		echo "Error: $SPIKE_BIN not found"
		exit 2
	fi

	inst_cnt_boot=6
	inst_cnt_total=$((inst_cnt_boot+inst_cnt_init+inst_cnt_slice))
	# rom:        0x1000 -    0x2000 size     0x1000
	# ram:        0x2000 - 0x2000000 size  0x1ffe000
	# clint:   0x2000000 - 0x20c0000 size    0xc0000
	# ram:     0x20c0000 - 0x4000000 size 0x1f400000
	# ram:     0x4000000 - 0xc000000 size 0x80000000
	mr_list=0x2000:0x1ffe000,0x20c0000:0x1f40000,0x40000000:0x80000000
	other_options=--log-commits
	#other_options=-l
	log_file=$slice_elf-$target_platform.log

	echo "------------------------"
	echo "Run slice"
	echo "------------------------"
	echo "Slice ELF  = " $slice_elf
	echo "Platform   = " $target_platform
	echo "Inst count = " $inst_cnt_boot " + " $inst_cnt_init " + " $inst_cnt_slice " Total " $inst_cnt_total
	echo "Log        = " $log_file
	$SPIKE_BIN --inst-toplimit=$inst_cnt_total -m$mr_list $other_options $slice_elf > $log_file 2>&1

	log_lines=`wc -l $log_file | cut -d ' ' -f 1`
	if [ "$log_lines" -lt "$inst_cnt_total" ]; then
		echo "Error: Running log not enough. Line count $log_lines, expected $inst_cnt_total"
		exit 1
	fi
	if [ "$log_lines" -gt "$((inst_cnt_total+10))" ]; then
		echo "Error: Running log too large. Line count $log_lines, expected $inst_cnt_total"
		exit 1
	fi
	pc_last=`tail -n 3 $log_file | head -n 1 | cut -d 'x' -f 2 | cut -b 9-16`
	if [ ! ${#pc_last} -eq 8 ]; then
		echo "Error: Invalid last PC $pc_last"
		exit 1
	fi
	grep $pc_last $slice_elf.S > /dev/null 2>&1
	if [ ! $? -eq 0 ]; then
		echo "Error: Last PC $pc_last not in $slice_elf.S"
		exit 1
	fi
	echo "Success"
	exit 0
elif [ "$target_platform" == "qemu" ]; then
	which $QEMU_BIN >> /dev/null
	if [ ! $? -eq 0 ]; then
		echo "Error: $QEMU_BIN not found"
		exit 2
	fi

	$QEMU_BIN -machine help | grep multico >> /dev/null
	if [ ! $? -eq 0 ]; then
		echo "Error: QEMU must support multico machine"
		exit 2
	fi

	$QEMU_BIN -nographic -machine multico -m 4G \
			  -kernel $slice_elf
fi

