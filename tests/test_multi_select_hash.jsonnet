/*
Copyright 2022 Aaron Bentley

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/
local exprFactory = import 'expr_factory.libsonnet';
local functions = import 'functions.libsonnet';
local ok = functions.ok;
local err = functions.err;
local jmespath = import 'jmespath.libsonnet';
local test = import 'test.libsonnet';
local test_eq = test.test_eq;
local call = functions.call;

local results = {
  test1_search: test_eq({ foo: 'bar' }, jmespath.search(
    "{foo: 'bar'}", {},
  )),
  test1_set: test_eq(null, jmespath.set(
    "{foo: 'bar'}", {}, 'asdf',
  )),
  test1_patch: test_eq(null, jmespath.patch(
    "{foo: 'bar'}", {}, 'asdf',
  )),
  test1_map: test_eq(null, jmespath.map(
    "{foo: 'bar'}", {}, 'asdf',
  )),
  test2_search: test_eq({ foo: 'baz' }, jmespath.search(
    '{foo: bar}', { bar: 'baz' },
  )),
};
test.asTest(results)
