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
  test1: test_eq(true, jmespath.search('`1`<`2`', [])),
  test2: test_eq(false, jmespath.search('`1`==`2`', [])),
  test3: test_eq(true, jmespath.search('`1`!=`2`', [])),
  test4: test_eq(false, jmespath.search('`1`>`2`', [])),
  test5: test_eq(false, jmespath.search('`1`>=`2`', [])),
  test6: test_eq(true, jmespath.search('`2`>=`2`', [])),
  test7: test_eq(true, jmespath.search('`1`<=`2`', [])),
  test8: test_eq(true, jmespath.search('`2`<=`2`', [])),
  test9: test_eq(['a', 'b'], jmespath.set('`2`<=`2`', ['a', 'b'], 6)),
  test10: test_eq(
    ['a', 'b'], jmespath.set('`2`<=`2`', ['a', 'b'], function(x) null)
  ),
  test11: test_eq(null, jmespath.search('`null`<`2`', [])),
  test12: test_eq(null, jmespath.search('`null`>`2`', [])),
  test13: test_eq(null, jmespath.search('`null`>=`2`', [])),
  test14: test_eq(null, jmespath.search('`null`<=`2`', [])),
};
test.asTest(results)
