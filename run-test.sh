#!/bin/bash
GEM5_DIR=/home/jzy/workspace/gem5
#GEM5_DIR=/home/jzy/workspace/git-worksapce/gem5

app=$1
slice=$2

interval=1000

date_str=`date +%Y%m%d.%H%M`
output_asm=./trace/trace-$app-$date_str.S

ulimit -c unlimited
ulimit -s 819200

rm -rf $GEM5_DIR/m5out/*

cmd="./sdfirm/scripts/gem5sim.sh -s gem5bbv -w $GEM5_DIR  -a arm64 -p $app -O xxx -i $interval"
echo $cmd ; $cmd ; sleep 2
cmd="./sdfirm/scripts/gem5sim.sh -s simpoint -w $GEM5_DIR"
echo $cmd ; $cmd ; sleep 2
cmd="./sdfirm/scripts/gem5sim.sh -s gem5cpt -w $GEM5_DIR  -a arm64 -p $app -O xxx -i $interval"
echo $cmd ; $cmd ; sleep 2
cmd="./sdfirm/scripts/gem5sim.sh -s gem5sim -w $GEM5_DIR  -a arm64 -p $app -O xxx -c $slice -x Exec"
echo $cmd ; $cmd ; sleep 2
date
#cp $GEM5_DIR/m5out/cpt.simpoint_01_*/simpoint_slice.S ./trace/ss01-$app-$date_str.S
