#!/bin/bash
set -eux
: ${TEST_DIR=../jmespath.test/}
: ${TESTS=basic}
python3 $TEST_DIR/bin/jp-compliance -e $(realpath compliance.sh)\
    --tests "$TESTS"
