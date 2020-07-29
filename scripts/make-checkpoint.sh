#!/bin/bash

GEM5_DIR=../gem5-dev
SIMPOINT_DIR=../Simpoint3.2

GEM5_MODE=debug
ARCH=RISCV
GEM5_BIN=$GEM5_DIR/build/$ARCH/gem5.$GEM5_MODE
SIMPOINT_BIN=$SIMPOINT_DIR/bin/simpoint

SIMPOINT_INTERVAL=1000

WORK_DIR=`pwd`

function usage
{
	echo "Usage:"
	echo "  $0 application"
	exit 0
}

if [ $# -gt 0 ]; then
	APP=$1
else
	usage
fi

if [ $1 == "--help" ]; then
	usage
fi

APP_DIR=$WORK_DIR/slicing/$APP

if [ ! -f $GEM5_BIN ]; then
	echo "Error: $GEM5_BIN not found"
	exit 1
fi

if [ ! -f $SIMPOINT_BIN ]; then
	echo "Error: $SIMPOINT_BIN not found"
	exit 1
fi

if [ ! -d $APP_DIR ]; then
	echo "Error: $APP_DIR not found"
	exit 1
fi

ls -d $APP_DIR/m5out/cpt.* 2>> /dev/null
if [ $? -eq 0 ]; then
	echo "Error: Checkpoint directory not clear: $APP_DIR/m5out/cpt.*"
	exit 1
fi

APP_CMD=$APP_DIR/$APP
APP_OPTION=`cat $APP_DIR/cmd`
APP_FULL_CMD="-c $APP_CMD -o $APP_OPTION"

echo "------------------------"
echo "Gem5     = " $GEM5_BIN
echo "SimPoint = " $SIMPOINT_BIN
echo "App      = " $APP_DIR
echo "------------------------"

echo "------------------------"
echo "Generate bbv"
echo "------------------------"
$GEM5_BIN --outdir=$APP_DIR/m5out \
		$GEM5_DIR/configs/example/se.py \
		$APP_FULL_CMD \
		--cpu-type=NonCachingSimpleCPU \
		--at-instruction \
		--simpoint-profile --simpoint-interval $SIMPOINT_INTERVAL

echo "------------------------"
echo "Run simpoint"
echo "------------------------"
$SIMPOINT_BIN -loadFVFile $APP_DIR/m5out/simpoint.bb.gz \
		-inputVectorsGzipped -maxK 30 \
		-saveSimpoints $APP_DIR/m5out/$ARCH.simpts \
		-saveSimpointWeights $APP_DIR/m5out/$ARCH.weights

echo "------------------------"
echo "Make checkpoints"
echo "------------------------"
$GEM5_BIN --outdir=$APP_DIR/m5out \
		$GEM5_DIR/configs/example/se.py \
		$APP_FULL_CMD \
		--cpu-type=NonCachingSimpleCPU \
		--at-instruction \
		--take-simpoint-checkpoint=$APP_DIR/m5out/RISCV.simpts,$APP_DIR/m5out/RISCV.weights,$SIMPOINT_INTERVAL,0

echo "------------------------"
echo "List resulting checkpoints"
echo "------------------------"
echo "(under $APP_DIR/m5out)"
ls -l $APP_DIR/m5out/

exit 0
