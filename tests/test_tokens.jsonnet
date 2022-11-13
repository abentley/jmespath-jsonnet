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
    token: { content: 1234, name: 'index' },
  }, tokens.token('[1234]')),
  test2: test_eq(null, tokens.token('[abcd]')),
  test9: test_eq({
    remainder: null,
    token: {
      name: 'filterProjection',
      content: [
        { content: 'asdf', name: 'idString' },
      ],
    },
  }, tokens.token('[?"asdf"]')),
  test3: test_eq({
    remainder: null,
    token: {
      name: 'filterProjection',
      content: [
        { content: 'asdf]', name: 'idString' },
      ],
    },
  }, tokens.token('[?"asdf]"]')),
  test4: test_eq({
    remainder: null,
    token: {
      name: 'filterProjection',
      content: [
        { content: 'asdf]', name: 'jsonLiteral' },
      ],
    },
  }, tokens.token('[?`asdf]`]')),

  test5: test_eq({
    remainder: null,
    token: {
      name: 'filterProjection',
      content: [
        { content: 'asdf]', name: 'rawString' },
      ],
    },
  }, tokens.token("[?'asdf]']")),
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
  test_parseNaturalNum: test_eq({
    remainder: 'q',
    token: { content: '78', name: 'naturalNum' },
  }, tokens.parseNaturalNum('78q')),
  test_parseNaturalNum2: test_eq(null, tokens.parseNaturalNum('q78q')),
  test_parseNaturalNum3: test_eq(null, tokens.parseNaturalNum('-78q')),
  test_parseIntToken: test_eq({
    remainder: 'q',
    token: { content: '78', name: 'int' },
  }, tokens.parseIntToken('78q')),
  test_parseIntToken2: test_eq(null, tokens.parseIntToken('q78q')),
  test_parseIntToken3: test_eq({
    remainder: ':',
    token: { content: '-78', name: 'int' },
  }, tokens.parseIntToken('-78:')),
  test_parseIntToken4: test_eq(null, tokens.parseIntToken('q-78q')),
};
test.asTest(results)
