#!/bin/bash
export JSONNET_PATH=$(dirname $(realpath $0))/src
jsonnet --tla-code-file json=/proc/self/fd/0 --tla-str jmespath="$1" --exec \
    "local lib = import 'jmespath.libsonnet';
    function(json, jmespath) lib.search(jmespath, json)"
