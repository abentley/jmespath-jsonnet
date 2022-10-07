#!/bin/bash
test_basename=${1-*}
if [ $# -gt 1 ]; then
    args="--tla-str testName=$2"
else
    arg=""
fi
test_files=($(find tests -name "$test_basename.jsonnet"))
for test_file in ${test_files[@]}; do
    if [ $test_file != ${test_files[0]} ]; then echo; fi
    echo $test_file
    jsonnet -SJ src -J test $args $test_file
done
