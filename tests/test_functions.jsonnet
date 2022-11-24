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
local call = exprFactory.ImplFunction.call;

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
    test_eq(err('invalid-arity', 'Expected 1 arguments, got 0'),
            exprFactory.ImplFunction.call('abs', [])),
  test5:
    test_eq(err('invalid-arity', 'Expected 1 arguments, got 2'),
            exprFactory.ImplFunction.call('abs', [-6, -6])),
  test6:
    test_eq(err('invalid-type',
                'Argument 0 had type "string" instead of "number"'),
            exprFactory.ImplFunction.call('abs', ['-6'])),
  test7:
    test_eq(ok(4.5),
            exprFactory.ImplFunction.call('avg', [[4, 5]])),
  test8:
    test_eq(ok(null),
            exprFactory.ImplFunction.call('avg', [[]])),
  test9:
    test_eq(ok(true),
            exprFactory.ImplFunction.call('contains', ['ab', 'a'])),
  test10:
    test_eq(ok(false),
            exprFactory.ImplFunction.call('contains', ['ab', 'q'])),
  test11:
    test_eq(ok(true),
            exprFactory.ImplFunction.call('contains', ['abc', 'ab'])),
  test12:
    test_eq(ok(true),
            exprFactory.ImplFunction.call('contains', [['ab', 'c'], 'ab'])),
  test13:
    test_eq(err('invalid-type', 'Invalid type: number'),
            exprFactory.ImplFunction.call('contains', [6, 'ab'])),
  test14:
    test_eq(ok(false),
            exprFactory.ImplFunction.call('contains', ['abc', 6])),
  test15:
    test_eq(ok(6),
            exprFactory.ImplFunction.call('ceil', [5.9])),
  test16:
    test_eq(ok(5),
            exprFactory.ImplFunction.call('floor', [5.9])),
  test17:
    test_eq(ok(true),
            exprFactory.ImplFunction.call('ends_with', ['fasd', 'asd'])),
  test18:
    test_eq(ok(false),
            exprFactory.ImplFunction.call('ends_with', ['fasd', 'gasd'])),
  test19:
    test_eq(ok('foo, bar'),
            exprFactory.ImplFunction.call('join', [', ', ['foo', 'bar']])),
  test20:
    test_eq(std.set(['foo', 'baz']),
            std.set(
              exprFactory.ImplFunction.call('keys', [{
                foo: 'bar',
                baz: 'qux',
              }]).ok
            )),
  test21:
    test_eq(ok(5), call('length', [[1, 1, 1, 1, 1]])),
  test22:
    test_eq(ok(3), call('length', ['111'])),
  test23:
    test_eq(ok(2), call('length', [{ foo: 'foo', bar: 'bar' }])),
  test24:
    test_eq(ok(9), call('max', [[1, 9, 5, 7]])),
  test25:
    test_eq(
      ok({ a: 'b', c: 'e' }),
      call('merge', [[{ a: 'b', c: 'd' }, { c: 'e' }]])
    ),
  test26:
    test_eq(ok('foo'), call('not_null', ['foo'])),
  test27:
    test_eq(ok(null), call('not_null', [null, null])),
  test28:
    test_eq(ok([4, 3, 2, 1]), call('reverse', [[1, 2, 3, 4]])),
  test29:
    test_eq(ok('4321'), call('reverse', ['1234'])),
  test30:
    test_eq(ok(true), call('starts_with', ['1234', '123'])),
  test31:
    test_eq(ok(false), call('starts_with', ['1234', '234'])),
  test32:
    test_eq(ok(['1234', '234']), call('to_array', [['1234', '234']])),
  test33:
    test_eq(ok(['1234']), call('to_array', ['1234'])),
  test34:
    test_eq(ok(123.4), call('to_number', ['123.4'])),
  test35:
    test_eq(ok(123.4), call('to_number', [123.4])),
  test36:
    test_eq(ok(null), call('to_number', [{}])),
  test37:
    test_eq(ok('object'), call('type', [{}])),
  test38:
    test_eq(std.set(['bar', 'qux']),
            std.set(
              call('values', [{
                foo: 'bar',
                baz: 'qux',
              }]).ok
            )),
};
test.asTest(results)
