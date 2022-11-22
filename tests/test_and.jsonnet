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
local jmespath = import 'jmespath.libsonnet';
local test = import 'test.libsonnet';
local test_eq = test.test_eq;

local results = {
  test1_search: test_eq('B', jmespath.search(
    'a && b', { a: 'A', b: 'B' },
  )),
  test1_set: test_eq({ a: 'A', b: 'B1' }, jmespath.set(
    'a && b', { a: 'A', b: 'B' }, 'B1',
  )),
  test2_search: test_eq(null, jmespath.search(
    'a && b', { a: null, b: 'B' },
  )),
  test2_set: test_eq({ a: 'A1', b: 'B' }, jmespath.set(
    'a && b', { a: null, b: 'B' }, 'A1',
  )),
  test3_search: test_eq([], jmespath.search(
    'a && b', { a: [], b: 'B' },
  )),
  test3_set: test_eq({ a: 'A1', b: 'B' }, jmespath.set(
    'a && b', { a: [], b: 'B' }, 'A1',
  )),
  test4_search: test_eq({}, jmespath.search(
    'a && b', { a: {}, b: 'B' },
  )),
  test4_set: test_eq({ a: 'A1', b: 'B' }, jmespath.set(
    'a && b', { a: {}, b: 'B' }, 'A1'
  )),
  test5_search: test_eq('', jmespath.search(
    'a && b', { a: '', b: 'B' },
  )),
  test5_set: test_eq({ a: 'A1', b: 'B' }, jmespath.set(
    'a && b', { a: '', b: 'B' }, 'A1'
  )),
  test6_search: test_eq(false, jmespath.search(
    'a && b', { a: false, b: 'B' },
  )),
  test6_set: test_eq({ a: 'A1', b: 'B' }, jmespath.set(
    'a && b', { a: false, b: 'B' }, 'A1'
  )),
  test7_search: test_eq(null, jmespath.search(
    'a && b', { b: 'B' },
  )),
  test7_set: test_eq({ b: 'B' }, jmespath.set(
    'a && b', { b: 'B' }, 'B1'
  )),
};
test.asTest(results)
