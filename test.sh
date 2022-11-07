#!/bin/bash
test_basename=${1-*}
test_files=($(find tests -name "$test_basename.jsonnet"))
error=false
for test_file in ${test_files[@]}; do
    if [ $# -gt 1 ]; then
        tests=($2)
    else
        tests=($(jsonnet -SJ src -J test --tla-str cmd=list $test_file))
    fi
    if [ $test_file != ${test_files[0]} ]; then echo; fi
    echo $test_file
    for test in ${tests[@]}; do
        CMD="jsonnet -SJ src -J test $args --tla-str testName=$test $test_file"
        if ! ($CMD 2> /dev/null); then
            error=true
            echo $test: ERROR
            $CMD
        fi
    done
done
if $error; then
    exit 1
fi
