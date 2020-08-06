#!/bin/bash

scripts_path=$(cd "$(dirname $0)"; pwd)
source $scripts_path/config.sh

if [ -z $GEM5_DIR ]; then
	GEM5_DIR=../gem5
fi
if [ -z $SIMPOINT_DIR ]; then
	SIMPOINT_DIR=../Simpoint3.2
fi

GEM5_BIN=$GEM5_DIR/build/$ARCH/gem5.$GEM5_MODE
SIMPOINT_BIN=$SIMPOINT_DIR/bin/simpoint

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

echo "------------------------"
echo "Gem5     = " $GEM5_BIN
echo "SimPoint = " $SIMPOINT_BIN
echo "App      = " $APP_DIR
echo "------------------------"

log_file=$APP_DIR/make-checkpoints-$APP.log
> $log_file

echo "------------------------"
echo "Generate bbv"
echo "------------------------"
$GEM5_BIN --outdir=$APP_DIR/m5out \
		$GEM5_DIR/configs/example/se.py \
		-c $APP_CMD -o "$APP_OPTION" \
		--cpu-type=NonCachingSimpleCPU \
		--at-instruction \
		--simpoint-profile --simpoint-interval $SIMPOINT_INTERVAL \
		>> $log_file 2>&1
if [ ! $? -eq 0 ]; then
	echo "Error: Failed to generate bbv. Details see $log_file"
	exit 1
fi

echo "------------------------"
echo "Run simpoint"
echo "------------------------"
$SIMPOINT_BIN -loadFVFile $APP_DIR/m5out/simpoint.bb.gz \
		-inputVectorsGzipped -maxK 30 \
		-saveSimpoints $APP_DIR/m5out/$ARCH.simpts \
		-saveSimpointWeights $APP_DIR/m5out/$ARCH.weights \
		>> $log_file 2>&1
if [ ! $? -eq 0 ]; then
	echo "Error: Failed to run simpoint. Details see $log_file"
	exit 1
fi

echo "------------------------"
echo "Make checkpoints"
echo "------------------------"
$GEM5_BIN --outdir=$APP_DIR/m5out \
		$GEM5_DIR/configs/example/se.py \
		-c $APP_CMD -o "$APP_OPTION" \
		--cpu-type=NonCachingSimpleCPU \
		--at-instruction \
		--take-simpoint-checkpoint=$APP_DIR/m5out/RISCV.simpts,$APP_DIR/m5out/RISCV.weights,$SIMPOINT_INTERVAL,0 \
		>> $log_file 2>&1
if [ ! $? -eq 0 ]; then
	echo "Error: Failed to make checkpoints. Details see $log_file"
	exit 1
fi

echo "------------------------"
echo "List resulting checkpoints"
echo "------------------------"
ls -ld $APP_DIR/m5out/cpt.*

exit 0
