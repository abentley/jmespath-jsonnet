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
  test1: test_eq([1, [2, 3], 4], jmespath.search('[*]', [1, [2, 3], 4])),
  test2: test_eq([1, 4], jmespath.search('[*].value', [
    { value: 1 },
    [{ value: 2 }, { value: 3 }],
    { value: 4 },
  ])),
  test3: test_eq([5, 5, 5], jmespath.set('[*]', [1, [2, 3], 4], 5)),
  test4: test_eq('[*]', jmespath.compile('[*]').repr()),
  test5: test_eq([6, 6, 6], jmespath.map(
    '[*]', [1, [2, 3], 4], function(x) 6
  )),
};
test.asTest(results)
