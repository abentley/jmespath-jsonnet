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
  test1_search: test_eq(4, jmespath.search(
    'abs(`-4`)', {},
  )),
  test1_set: test_eq({ a: 'A', b: 'B' }, jmespath.set(
    'abs(`-4`)', { a: 'A', b: 'B' }, 'B1',
  )),
};
test.asTest(results)
