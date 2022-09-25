#!/bin/bash
for test in $(find tests -name '*.jsonnet'); do
    echo $test
    jsonnet -SJ src -J tests $test
done
