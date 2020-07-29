#!/bin/bash

GEM5_DIR=../gem5-dev
SIMPOINT_DIR=../Simpoint3.2

GEM5_MODE=debug
ARCH=RISCV
GEM5_BIN=$GEM5_DIR/build/$ARCH/gem5.$GEM5_MODE

WORK_DIR=`pwd`

APP=hello

APP_DIR=$WORK_DIR/slicing/$APP
APP_CMD=$APP_DIR/$APP
APP_OPTION=`cat $APP_DIR/cmd`
APP_FULL_CMD="-c $APP_CMD -o $APP_OPTION"

if [ ! -f $GEM5_BIN ]; then
	echo "Error: $GEM5_BIN not found"
	exit 1
fi

if [ ! -d $APP_DIR ]; then
	echo "Error: $APP_DIR not found"
	exit 1
fi

CHECKPOINT_CNT=`ls -d $APP_DIR/m5out/cpt.* 2>> /dev/null | wc -l`
if [ $CHECKPOINT_CNT -eq 0 ]; then
	echo "Error: No checkpoint directory under $APP_DIR/m5out/"
	exit 1
fi

echo "------------------------"
echo "Gem5     = " $GEM5_BIN
echo "App      = " $APP_DIR
echo "------------------------"
echo "(checkpoint count = $CHECKPOINT_CNT)"

for i in $(seq 1 $CHECKPOINT_CNT); do
	echo "------------------------"
	echo "Generate slice for checkpoint $i"
	echo "------------------------"
	echo ""
	$GEM5_BIN --outdir=$APP_DIR/m5out \
			--debug-flags=Exec \
			$GEM5_DIR/configs/example/se.py \
			$APP_FULL_CMD \
			--cpu-type=NonCachingSimpleCPU \
			--at-instruction \
			--enable-simpoint-slicing \
			--restore-simpoint-checkpoint \
			--checkpoint-dir $APP_DIR/m5out/ \
			-r $i
done


echo "------------------------"
echo "List resulting slices"
echo "------------------------"
echo "(under $APP_DIR/m5out)"
ls -l $APP_DIR/m5out/cpt.*/simpoint_slice.S

exit 0
