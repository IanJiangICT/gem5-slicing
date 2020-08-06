#!/bin/bash

scripts_path=$(cd "$(dirname $0)"; pwd)
source $scripts_path/config.sh

target_platform="spike"

if [ $# -gt 0 ]; then
	slice_file=$1
else
	echo "Usage:"
	echo "  slice-build.sh slice-file.S [target-platform]"
	echo "Example:"
	echo "  slice-build.sh slice-file.S spike"
	exit 1
fi
if [ $# -gt 1 ]; then
	target_platform=$2
fi

if [ "$target_platform" == "spike" ]; then
	FREE_MEM_BASE=0x40000000
	FREE_MEM_SIZE=0x20000000
fi

GCC=$GNU_PREFIX-gcc
OBJDUMP=$GNU_PREFIX-objdump

CFLAGS="-march=rv64g -mabi=lp64 -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles"
CFLAGS+=" -DFREE_MEM_BASE=$FREE_MEM_BASE"
CFLAGS+=" -DFREE_MEM_SIZE=$FREE_MEM_SIZE"

ld_file=$scripts_path/../src/$target_platform.ld
boot_head=$scripts_path/../src/$target_platform.S

if [ ! -f $slice_file ]; then
	echo "Error: $slice_file not found"
	exit 2
fi

which $GCC >> /dev/null
if [ ! $? -eq 0 ]; then
	echo "Error: $GCC not found"
	exit 2
fi

$GCC $CFLAGS -T$ld_file $boot_head $slice_file -o $slice_file.elf
$OBJDUMP -h $slice_file.elf
$OBJDUMP -D $slice_file.elf > $slice_file.elf.S

