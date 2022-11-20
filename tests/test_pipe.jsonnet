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
  test1: test_eq(0, jmespath.search(
    '[*]|[0]', [0, 1]
  )),
  test2: test_eq('bar', jmespath.search(
    '*|[1]', { foo: 'bar', baz: 'qux' }
  )),
  test3: test_eq(0, jmespath.search(
    '|[0]', [0, 1]
  )),
  test4: test_eq('[*]|[0]', jmespath.compile('[*]|[0]').repr()),
  test5: test_eq([5, 1], jmespath.set(
    '[*]|[0]', [0, 1], 5
  )),
  test6: test_eq({ foo: 5, baz: 'qux' }, jmespath.set(
    '*|[1]', { foo: 'bar', baz: 'qux' }, 5
  )),
  test7: test_eq([5, 1], jmespath.set(
    '|[0]', [0, 1], 5
  )),
  test8: test_eq([5, 1], jmespath.set(
    '[:]|[0]', [0, 1], 5
  )),
  test9: test_eq([0, 1, [2, 5]], jmespath.set(
    '[]|[3]', [0, 1, [2, 3]], 5
  )),
  test10: test_eq([0, 1, [2, 5]], jmespath.map(
    '[]|[3]', [0, 1, [2, 3]], function(x) 5
  )),
  test11: test_eq(5, jmespath.search('*.b|[0]', { a: { b: 5 } })),
};
test.asTest(results)
