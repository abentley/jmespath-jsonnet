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
  test1: test_eq('baz', jmespath.search('\n foo \n. bar',
                                        { foo: { bar: 'baz' } })),
  test2: test_eq('b', jmespath.search(' [ \n1\n ] ',
                                      ['a', 'b', 'c', 'd', 'e', 'f'])),
  test3: test_eq([1, [2, 3], 4], jmespath.search(
    ' * ', { '0': 1, '1': [2, 3], '2': 4 }
  )),
  test4: test_eq(
    [0, 1, 2, 3, 4],
    jmespath.search(' [ 0 : 5 ] ', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
  ),
  test5: test_eq(0, jmespath.search(
    ' [ * ] | [ 0 ] ', [0, 1]
  )),
  test6: test_eq(true, jmespath.search(' `1` < `2` ', [])),
  test7: test_eq(
    [
      { keep: 'true', value: 0 },
      { keep: 'true', value: 3 },
    ],
    jmespath.search(" [?   keep == 'true' ] ", [
      { keep: 'true', value: 0 },
      { keep: 'false', value: 1 },
      { keep: 'true', value: 3 },
    ])
  ),
  test8: test_eq([1, 2, 3, 4], jmespath.search(' [ ] ', [1, [2, 3], 4])),
};
test.asTest(results)
