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
  test1: test_eq('b', jmespath.search('[1]', ['a', 'b', 'c', 'd', 'e', 'f'])),
  test2: test_eq('b', jmespath.search('x1[1]', { x1: [
    'a',
    'b',
    'c',
    'd',
    'e',
    'f',
  ] })),
  test3:: test_eq(
    ['a', 'bb', 'c', 'd', 'e', 'f'], jmespath.doPatch(
      ['a', 'b', 'c', 'd', 'e', 'f'], '[1]', 'b'
    )
  ),
  test4:: test_eq(
    [{ b: 'd' }, { b: 'c' }], jmespath.doPatch(
      [{ b: 'c' }, { b: 'c' }], '[0]', { b: 'd' }
    )
  ),
  // patch works as long as the top-level item is an object
  test5::
    local data = { a: [{ b: 'c', d: { e: 'f' } }] };
    test_eq({ a: [{ b: 'c', d: { e: 'g' } }] },
            data + jmespath.patch('a[0]d', { e: 'g' })),
  test6: test_eq(
    [{ b: 'd' }, { b: 'c' }], jmespath.set(
      '[0].b', [{ b: 'c' }, { b: 'c' }], 'd'
    )
  ),
  test7::
    local extracted = jmespath.extractLast(jmespath.compile('[0]b')); test_eq(
      {}, extracted[1].genSetPatch('d'),
    ),
  test8:
    test_eq({
      type: 'index',
      index: 2,
    }, jmespath.compile('[2]')),
  test9:
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
  test10:
    test_eq('[1][2]', jmespath.compile('[1][2]').repr()),
  test11:
    test_eq('[1].[2]', jmespath.compile('[1].[2]').repr()),
  test12:
    test_eq(null, jmespath.search('[1]', 5)),
  test13:
    test_eq(5, jmespath.set('[1]', 5, 20)),
  test14:
    test_eq(5, jmespath.map('[1]', 5, function(x) 20)),
};
test.asTest(results)
