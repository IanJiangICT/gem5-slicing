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

instr_count=1000

if [ "$target_platform" == "spike" ]; then
	which $SPIKE_BIN >> /dev/null
	if [ ! $? -eq 0 ]; then
		echo "Error: $SPIKE_BIN not found"
		exit 2
	fi
	mr_list=0x92000:0x28000,0x40000000:0x80000000
	other_options=--log-commits
	other_options=-l
	$SPIKE_BIN --inst-toplimit=$instr_count -m$mr_list $other_options $slice_elf
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

