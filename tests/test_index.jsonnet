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
local json = import 'test_index.json';

local search_test = test.search_test;


local results = {
  test1_search: test_eq('b', jmespath.search('[1]', ['a', 'b', 'c', 'd', 'e', 'f'])),
  test2_search: test_eq('b', jmespath.search('x1[1]', { x1: [
    'a',
    'b',
    'c',
    'd',
    'e',
    'f',
  ] })),
  test3_set: test_eq(
    [{ b: 'd' }, { b: 'c' }], jmespath.set(
      '[0].b', [{ b: 'c' }, { b: 'c' }], 'd'
    )
  ),
  test4_compile:
    test_eq({
      type: 'index',
      index: 2,
    }, jmespath.compile('[2]')),
  test5_compile:
    test_eq({
      type: 'joiner',
      left: {
        type: 'index',
        index: 1,
      },
      right: {
        type: 'index',
        index: 2,
      },
    }, jmespath.compile('[1][2]')),
  test5_repr:
    test_eq('[1][2]', jmespath.compile('[1][2]').repr()),
  test6_compile:
    test_eq('[1].[2]', jmespath.compile('[1].[2]').repr()),
  test6_search:
    test_eq(null, jmespath.search('[1]', 5)),
  test6_set:
    test_eq(5, jmespath.set('[1]', 5, 20)),
  test6_map:
    test_eq(5, jmespath.map('[1]', 5, function(x) 20)),
  test7_search: search_test(json[0], 0),
};
test.asTest(results)
