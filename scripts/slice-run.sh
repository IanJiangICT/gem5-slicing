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
	mr_list=0x92000:0x28000,0x40000000:0x80000000
	other_options=--log-commits
	other_options=-l
	log_file=$slice_elf-$target_platform.log

	echo "------------------------"
	echo "Run slice"
	echo "------------------------"
	echo "Slice ELF  = " $slice_elf
	echo "Platform   = " $target_platform
	echo "Inst count = " $inst_cnt_boot " + " $inst_cnt_init " + " $inst_cnt_slice " Total " $inst_cnt_total
	echo "Log        = " $log_file
	$SPIKE_BIN --inst-toplimit=$inst_cnt_total -m$mr_list $other_options $slice_elf > $log_file 2>&1
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

