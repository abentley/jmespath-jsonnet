#!/bin/bash
: ${jp=$(realpath jp)}
: ${RUNNER_DIR=../jmespath.test/}
: ${TEST_DIR=$RUNNER_DIR/tests}
: ${TESTS=basic}
set -eux
python3 $RUNNER_DIR/bin/jp-compliance -e "$jp"\
    -d $TEST_DIR --tests "$TESTS"
