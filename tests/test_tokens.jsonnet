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
  test9: test_eq({
    remainder: null,
    token: {
      name: 'filterProjection',
      content: [
        { content: 'asdf', name: 'idString' },
      ],
    },
  }, tokens.token('[?"asdf"]')),
  test10: test_eq({
    token: { name: null, content: [
      { content: 'asdf', name: 'jsonLiteral' },
      { content: 'xyz', name: 'id' },
    ] },
    remainder: null,
  }, tokens.someTokens('`asdf`xyz')),
  test11: test_eq(
    tokens.rawToken(null, [
      { content: 'a', name: 'id' },
      { content: [{ content: 'b', name: 'id' }], name: 'pipe' },
    ], null),
    tokens.someTokens('a|b', parsers=tokens.ultraTokens)
  ),
  test12: test_eq(
    tokens.rawToken(null, [
      { content: 'a', name: 'id' },
      { content: [{ content: 'c', name: 'id' }], name: 'subexpression' },
      { content: [{ content: 'b', name: 'id' }], name: 'pipe' },
    ], null),
    tokens.someTokens('a.c|b', parsers=tokens.ultraTokens)
  ),
  test13: test_eq({
    token: { name: null, content: [
      { content: 'asdf', name: 'jsonLiteral' },
      { content: '_x_yz', name: 'id' },
    ] },
    remainder: null,
  }, tokens.someTokens('`asdf`_x_yz')),
  test14: test_eq({
    token: { name: null, content: [{ name: 'current', content: '@' }] },
    remainder: null,
  }, tokens.someTokens('@')),
  test15: test_eq({
    token: { name: null, content: [
      { name: 'id', content: 'a' },
      { name: 'or', content: [{ name: 'id', content: 'b' }] },
    ] },
    remainder: null,
  }, tokens.someTokens('a||b')),
  test16: test_eq({
    token: { name: null, content: [
      { name: 'id', content: 'a' },
      { name: 'and', content: [{ name: 'id', content: 'b' }] },
    ] },
    remainder: null,
  }, tokens.someTokens('a&&b')),
  test17: test_eq({
    token: { name: null, content: [
      { name: 'not', content: [{ name: 'id', content: 'a' }] },
    ] },
    remainder: null,
  }, tokens.someTokens('!a')),
  test18: test_eq({
    token: { name: null, content: [
      { name: 'id', content: 'a' },
      { name: 'comparator', content: { op: '!=', tokens: [{ name: 'id', content: 'b' }] } },
    ] },
    remainder: null,
  }, tokens.someTokens('a!=b')),
  test19: test_eq({
    token: { name: null, content: [
      { name: 'id', content: 'a' },
    ] },
    remainder: '=b',
  }, tokens.someTokens('a=b')),
  test20: test_eq({
    token: { name: null, content: [
      { name: 'function', content: { name: 'f', args: [] } },
    ] },
    remainder: null,
  }, tokens.someTokens('f()')),
  test21: test_eq({
    token: { name: null, content: [
      { name: 'function', content: { name: 'f', args: [
        [{ name: 'id', content: 'a' }],
      ] } },
    ] },
    remainder: null,
  }, tokens.someTokens('f(a)')),
  test22: test_eq({
    token: { name: null, content: [
      { name: 'function', content: { name: 'f', args: [
        [{ name: 'id', content: 'a' }],
        [{ name: 'id', content: 'b' }],
      ] } },
    ] },
    remainder: null,
  }, tokens.someTokens('f(a,b)')),
  test23: test_eq({
    token: {
      name: 'rawString',
      content: '',
    },
    remainder: null,
  }, tokens.token("''")),
  test_parseNaturalNum: test_eq({
    remainder: 'q',
    token: { content: '78', name: 'naturalNum' },
  }, tokens.parseNaturalNum('78q')),
  test_parseEscapedString1: test_eq(null, tokens.parseEscapedString('\u0019')),
  test_parseEscapedString2: test_eq(
    { result: 'abc', remainder: '"%' }, tokens.parseEscapedString('abc"%')
  ),
  test_parseEscapedString3: test_eq(
    { result: '', remainder: '"%' }, tokens.parseEscapedString('"%')
  ),
  test_parseEscapedString4: test_eq(
    { result: @'\e', remainder: '"' }, tokens.parseEscapedString(@'\\e"')
  ),
  test_parseEscapedString5: test_eq(
    null, tokens.parseEscapedString(@'\q"')
  ),
  test_parseEscapedString6: test_eq(
    { result: '/\b\f\n\r\t', remainder: '"' },
    tokens.parseEscapedString(@'\/\b\f\n\r\t"')
  ),
  test_parseEscapedString7: test_eq(
    { result: 'ሴ', remainder: '"' },
    tokens.parseEscapedString(@'\u1234"')
  ),
  test_parseEscapedString8: test_eq(
    null,
    tokens.parseEscapedString(@'\u123"')
  ),
  test_parseEscapedString9: test_eq(
    null,
    tokens.parseEscapedString(@'\u123g"')
  ),
  test_parseEscapedString10: test_eq(
    { result: '"', remainder: '"' },
    tokens.parseEscapedString(@'\""')
  ),
  test_parseNaturalNum2: test_eq(null, tokens.parseNaturalNum('q78q')),
  test_parseNaturalNum3: test_eq(null, tokens.parseNaturalNum('-78q')),
  test_parseIntToken: test_eq({
    remainder: 'q',
    token: { content: 78, name: 'int' },
  }, tokens.parseIntToken('78q')),
  test_parseIntToken2: test_eq(null, tokens.parseIntToken('q78q')),
  test_parseIntToken3: test_eq({
    remainder: ':',
    token: { content: -78, name: 'int' },
  }, tokens.parseIntToken('-78:')),
  test_parseIntToken4: test_eq(null, tokens.parseIntToken('q-78q')),
};
test.asTest(results)
