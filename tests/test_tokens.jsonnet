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
local test = import 'test.libsonnet';
local tokens = import 'tokens.libsonnet';
local test_eq = test.test_eq;

local results = {
  test1: test_eq({
    remainder: null,
    token: { content: 'asdf', name: 'index' },
  }, tokens.token('[asdf]')),
  test2: test_eq({
    remainder: null,
    token: { content: '"asdf"', name: 'index' },
  }, tokens.token('["asdf"]')),
  test3: test_eq({
    remainder: null,
    token: { content: '"asdf]"', name: 'index' },
  }, tokens.token('["asdf]"]')),
  test4: test_eq({
    remainder: null,
    token: { content: '`asdf]`', name: 'index' },
  }, tokens.token('[`asdf]`]')),
  test5: test_eq({
    remainder: null,
    token: { content: "'asdf]'", name: 'index' },
  }, tokens.token("['asdf]']")),
  test6: test_eq({
    remainder: null,
    token: { content: 'asdf"', name: 'rawString' },
  }, tokens.token("'asdf\"'")),
  test7: test_eq({
    remainder: null,
    token: { content: 'asdf', name: 'idString' },
  }, tokens.token('"asdf"')),
  test8: test_eq({
    remainder: null,
    token: { content: "asdf'", name: 'idString' },
  }, tokens.token('"asdf\'"')),
};
test.asTest(results)
