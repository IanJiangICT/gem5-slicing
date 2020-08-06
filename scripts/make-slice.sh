#!/bin/bash

scripts_path=$(cd "$(dirname $0)"; pwd)
source $scripts_path/config.sh

if [ -z $GEM5_DIR ]; then
	GEM5_DIR=../gem5
fi

GEM5_BIN=$GEM5_DIR/build/$ARCH/gem5.$GEM5_MODE

WORK_DIR=`pwd`

function usage
{
	echo "Usage:"
	echo "  $0 application [checkpoint-num]"
	echo "Example:"
	echo "  $0 hello   # for all checkpoints"
	echo "  $0 hello 1 # for single checkpoint: the 1st one"
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


# Which checkpoint to make slice for
CHECKPOINT_NUM=0 # All checkpoints on default
if [ $# -gt 1 ]; then
	CHECKPOINT_NUM=$2 # Single checkpoint if specified
fi

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

APP_CMD=$APP_DIR/$APP
APP_OPTION=`cat $APP_DIR/cmd`
APP_FULL_CMD="-c $APP_CMD -o $APP_OPTION"

echo "------------------------"
echo "Gem5     = " $GEM5_BIN
echo "App      = " $APP_DIR
echo "------------------------"
echo "(total checkpoint count = $CHECKPOINT_CNT)"

for i in $(seq 1 $CHECKPOINT_CNT); do
	if [ ! $i -eq $CHECKPOINT_NUM -a ! $CHECKPOINT_NUM -eq 0 ]; then
		continue
	fi
	log_file=$APP_DIR/make-slice-$APP-$i.log
	echo "Generate slice for checkpoint $i"
	$GEM5_BIN --outdir=$APP_DIR/m5out \
			--debug-flags=Exec \
			$GEM5_DIR/configs/example/se.py \
			$APP_FULL_CMD \
			--cpu-type=NonCachingSimpleCPU \
			--at-instruction \
			--enable-simpoint-slicing \
			--restore-simpoint-checkpoint \
			--checkpoint-dir $APP_DIR/m5out/ \
			-r $i \
			> $log_file 2>&1
	if [ ! $? -eq 0 ]; then
		echo "Error: Failed to generate slice. Details see $log_file"
		continue
	fi

	echo "Result slice"
	slice_file=`ls -t $APP_DIR/m5out/cpt.*/simpoint_slice.S | head -n 1`
	log_file=$APP_DIR/slice-parse-$APP-$i.log
	$scripts_path/slice-parse.py $slice_file > $log_file
	ls -l $slice_file*

	CC=$GNU_PREFIX-gcc
	which $CC > /dev/null
	if [ $? -eq 0 ]; then
		echo "Compile slice as checking"
		$CC -c $slice_file.S -o /dev/null
		if [ $? -eq 0 ]; then
			echo "Compile slice as checking OK"
		else
			echo "Compile slice as checking Failed"
		fi
	fi

	log_file=$APP_DIR/slice-build-$APP-$i.log
	$scripts_path/slice-build.sh $slice_file.S > $log_file
	ls -l $slice_file*elf*
done

exit 0
