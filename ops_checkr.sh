#!/bin/bash
set -e
nimble build -d:release -d:printAst
export FILE=examples/example.bm
#export FILE=examples/optimization_test.bm
#export FILE=examples/benchmark_test.bm
time ./bin/bm -f:"$FILE" > with_opts.txt 2>&1
nimble build -d:release -d:disableBMathOpt -d:printAst
time ./bin/bm -f:"$FILE" > without_opts.txt 2>&1
code --diff without_opts.txt with_opts.txt
sleep 5
rm without_opts.txt with_opts.txt