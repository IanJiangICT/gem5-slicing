#!/bin/bash
GEM5_DIR=/home/jzy/workspace/gem5

app=hello

date_str=`date +%Y%m%d.%H%M`
output_asm=./trace/trace-$app-$date_str.S

./sdfirm/scripts/gem5sim.sh -s gem5bbv -w $GEM5_DIR  -a arm64 -p $app -i 1000
sleep 2
./sdfirm/scripts/gem5sim.sh -s simpoint -w $GEM5_DIR
sleep 2
./sdfirm/scripts/gem5sim.sh -s gem5cpt -w $GEM5_DIR  -a arm64 -p $app -i 1000
sleep 2
./sdfirm/scripts/gem5sim.sh -s gem5sim -w $GEM5_DIR  -a arm64 -p $app -c 1 -x Exec \
    > $output_asm
date
ls -l $output_asm
cp $GEM5_DIR/m5out/cpt.simpoint_00_inst_1000_weight_0.250000_interval_1000_warmup_0/simpoint_slice.S ./trace/ss00-$app-$date_str.S
