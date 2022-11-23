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
local ok = exprFactory.ok;
local err = exprFactory.err;
local jmespath = import 'jmespath.libsonnet';
local test = import 'test.libsonnet';
local test_eq = test.test_eq;

local results = {
  test1_search: test_eq(4, jmespath.search(
    'abs(`-4`)', {},
  )),
  test1_set: test_eq({ a: 'A', b: 'B' }, jmespath.set(
    'abs(`-4`)', { a: 'A', b: 'B' }, 'B1',
  )),
  test2_search:: test_eq(4, jmespath.search(
    'asdf(`-4`)', {},
  )),
  test2:
    test_eq(ok(6), exprFactory.ImplFunction.call('abs', [-6])),
  test3:
    test_eq(err('Unknown function', 'asdf'),
            exprFactory.ImplFunction.call('asdf', [-6])),
  test4:
    test_eq(err('invalid-arity', 'Wrong number of arguments'),
            exprFactory.ImplFunction.call('abs', [])),
  test5:
    test_eq(err('invalid-arity', 'Wrong number of arguments'),
            exprFactory.ImplFunction.call('abs', [-6, -6])),
  test6:
    test_eq(err('invalid-type',
                'Argument 0 had type "string" instead of "number"'),
            exprFactory.ImplFunction.call('abs', ['-6'])),
};
test.asTest(results)
