#!/bin/bash

cp projects/cpu_axi_diff/vsrc/* projects/cpu_axi_diff/build/
#Using for batch mode
if [ $1 = "-b" ]; then
	bash build.sh -e cpu_axi_diff -b -r "-i non-output/$2-tests" -m "EMU_TRACE=1 WITH_DRAMSIM3=1"
#Using for certain test in riscv-tests
elif [ $1 = "rt" ]; then
	bash build.sh -e cpu_axi_diff -d -s -a "-i custom-output/rt-thread/rtthread.bin " -m "EMU_TRACE=1 WITH_DRAMSIM3=1" -b
elif [ $2 = "riscv" ]; then
	bash build.sh -e cpu_axi_diff -d -s -a "-i non-output/$2-tests/$1-$2-tests.bin --dump-wave -b 0" -m "EMU_TRACE=1 WITH_DRAMSIM3=1" -b -w
#Using for certain test in cpu-tests
elif [ $2 = "cpu" ]; then
	bash build.sh -e cpu_axi_diff -d -s -a "-i non-output/$2-tests/$1-$2-tests.bin --dump-wave -b 0" -m "EMU_TRACE=1 WITH_DRAMSIM3=1" -b -w
elif [ $1 = "coremark" ]; then
	bash build.sh -e cpu_axi_diff -d -s -a "-i non-output/coremark/coremark.bin " -m "EMU_TRACE=1 WITH_DRAMSIM3=1" -b
elif [ $1 = "axi" ]; then
  	bash build.sh -e cpu_axi_diff -d -s -a "-i inst_diff.bin --dump-wave -b 0" -m "EMU_TRACE=1 WITH_DRAMSIM3=1" -b -w
fi
if [ $1 = "clean" ]; then
	rm -rf projects/cpu_axi_diff/build
fi
