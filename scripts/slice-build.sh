#!/bin/bash

scripts_path=$(cd "$(dirname $0)"; pwd)
source $scripts_path/config.sh

GCC=$GNU_PREFIX-gcc
OBJDUMP=$GNU_PREFIX-objdump

CFLAGS="-march=rv64g -mabi=lp64 -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles"

LD_FILE=$scripts_path/../src/$TARGET_PLATFORM.ld
BOOT_HEAD=$scripts_path/../src/$TARGET_PLATFORM.S

if [ $# -gt 0 ]; then
	slice_file=$1
else
	echo "Usage:"
	echo "  slice-build.sh slice-file.S"
	exit 1
fi

if [ ! -f $slice_file ]; then
	echo "Error: $slice_file not found"
	exit 2
fi

which $GCC >> /dev/null
if [ ! $? -eq 0 ]; then
	echo "Error: $GCC not found"
	exit 2
fi

$GCC $CFLAGS -T$LD_FILE $BOOT_HEAD $slice_file -o $slice_file.elf
$OBJDUMP -h $slice_file.elf
$OBJDUMP -D $slice_file.elf > $slice_file.elf.S

