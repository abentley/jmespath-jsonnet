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
  test1_search: test_eq('baz', jmespath.search('@.foo.bar', {
    foo: { bar: 'baz' },
  })),
  test1_set: test_eq(
    { foo: { bar: 'baz2' } },
    jmespath.set('@.foo.bar', {
      foo: { bar: 'baz' },
    }, 'baz2')
  ),
  test2_search: test_eq('baz', jmespath.search('@', 'baz')),
  test2_set: test_eq('baz2', jmespath.set('@', 'baz', 'baz2')),
  test3_search: test_eq('baz', jmespath.search('@[1]', ['bar', 'baz'])),
  test3_set: test_eq(['bar', 'baz2'], jmespath.set(
    '@[1]', ['bar', 'baz'], 'baz2'
  )),
};
test.asTest(results)
