#!/bin/sh
NOW=$(date +"%m-%d-%Y")
node scripts/run_benchmarks.js >> $OUTPUT/stdout_$NOW  2>&1