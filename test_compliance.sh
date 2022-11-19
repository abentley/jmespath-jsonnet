#!/bin/bash
: ${jp=$(realpath jp)}
: ${RUNNER_DIR=../jmespath.test/}
: ${TEST_DIR=$RUNNER_DIR/tests}
: ${TESTS=basic slice}
if [ -n "$TESTS" ]; then
    TEST_ARGS="--tests $TESTS"
else
    TEST_ARGS=""
fi   
set -eux
python3 $RUNNER_DIR/bin/jp-compliance -e "$jp"\
    -d $TEST_DIR $TEST_ARGS
