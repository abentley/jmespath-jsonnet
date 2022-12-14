#!/bin/bash
#
# Copyright 2022 Aaron Bentley
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
set -eu

test_basename=${1-*}
test_files=($(find tests -name "$test_basename.jsonnet"))
error=false
if [ "${#test_files[@]}" == "0" ]; then
    echo No test files found
    exit 1
fi
for test_file in ${test_files[@]}; do
    if [ $# -gt 1 ]; then
        tests=($2)
    else
        tests=($(jsonnet -SJ src -J test --tla-str cmd=list $test_file))
    fi
    if [ $test_file != ${test_files[0]} ]; then echo; fi
    echo $test_file
    for test in ${tests[@]}; do
        CMD="jsonnet -SJ src --max-trace 1000 -J test --tla-str testName=$test $test_file"
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
