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
  test1: test_eq(
    [0, 1, 2, 3, 4],
    jmespath.search('[0:5]', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
  ),
  test2: test_eq(
    [5, 6, 7, 8, 9],
    jmespath.search('[5:10]', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
  ),
  test3: test_eq(
    [0, 1, 2, 3, 4],
    jmespath.search('[:5]', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
  ),
  test4: test_eq(
    [5, 6, 7, 8, 9],
    jmespath.search('[5:]', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
  ),
  test5: test_eq(
    [0, 2, 4, 6, 8],
    jmespath.search('[::2]', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
  ),
  test6: test_eq(
    [0, 1, 2, 3],
    jmespath.search('[:-6]', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
  ),
  test7: test_eq(
    [6, 7, 8, 9],
    jmespath.search('[-4:]', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
  ),
  test8: test_eq(
    [9, 7, 5, 3, 1],
    jmespath.search('[::-2]', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
  ),
  test9: test_eq(
    [],
    jmespath.search('[0:5][2]', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
  ),
  test10: test_eq(
    [],
    jmespath.search('[5:10][2]', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
  ),
  test11: test_eq(
    [],
    jmespath.search('[::2][3]', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
  ),
  test12: test_eq(
    [12, 12, 12, 12, 12, 5, 6, 7, 8, 9],
    jmespath.set('[:5]', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], 12)
  ),
  test13: test_eq(
    [0, 1, 2, 3, 4, 12, 12, 12, 12, 12],
    jmespath.set('[5:]', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], 12)
  ),
  test14: test_eq(
    [12, 1, 12, 3, 12, 5, 12, 7, 12, 9],
    jmespath.set('[::2]', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], 12)
  ),
  test15: test_eq(
    [12, 12, 12, 12, 4, 5, 6, 7, 8, 9],
    jmespath.set('[:-6]', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], 12)
  ),
  test16: test_eq(
    [0, 1, 2, 3, 4, 5, 12, 12, 12, 12],
    jmespath.set('[-4:]', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], 12)
  ),
  test17: test_eq(
    [0, 12, 2, 12, 4, 12, 6, 12, 8, 12],
    jmespath.set('[::-2]', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], 12)
  ),
  test18: test_eq(
    // Noop because projection.
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
    jmespath.set('[0:5][2]', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], 12)
  ),
  test_projection1: test_eq(
    [2, 4],
    jmespath.search('[2:5].hello', [
      { hello: 0 },
      { hello: 1 },
      { hello: 2 },
      {},
      { hello: 4 },
    ])
  ),
  test_projection2: test_eq(
    [
      { hello: 0 },
      { hello: 1 },
      { hello: 9 },
      {},
      { hello: 9 },
    ],
    jmespath.set('[2:5].hello', [
      { hello: 0 },
      { hello: 1 },
      { hello: 2 },
      {},
      { hello: 4 },
    ], 9),
  ),
  test_projection3: test_eq(
    [
      [0],
      [1],
      [9],
      [],
      [9],
    ],
    jmespath.set('[2:5][0]', [
      [0],
      [1],
      [2],
      [],
      [4],
    ], 9)
  ),
  test_projection4: test_eq(
    [
      [0],
      [1],
      [9],
      [],
      [9],
    ],
    jmespath.map('[2:5][0]', [
      [0],
      [1],
      [2],
      [],
      [4],
    ], function(x) 9)
  ),
};
test.asTest(results)
