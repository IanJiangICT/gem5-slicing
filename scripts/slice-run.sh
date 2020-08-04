#!/bin/bash

scripts_path=$(cd "$(dirname $0)"; pwd)
source $scripts_path/config.sh



if [ $# -gt 0 ]; then
	slice_elf=$1
else
	echo "Usage:"
	echo "  slice-run.sh slice.elf"
	exit 1
fi

if [ ! -f $slice_elf ]; then
	echo "Error: $slice_elf not found"
	exit 2
fi

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
