local jmespath = import 'jmespath.libsonnet';
local test = import 'test.libsonnet';
local test_eq = test.test_eq;

local results = {
  test1: test_eq(
    [
      { keep: 'true', value: 0 },
      { keep: 'true', value: 3 },
    ],
    jmespath.search("[?keep=='true']", [
      { keep: 'true', value: 0 },
      { keep: 'false', value: 1 },
      { keep: 'true', value: 3 },
    ])
  ),
  test2: test_eq(
    [
      { keep: 'false', value: 1 },
    ],
    jmespath.search("[?keep!='true']", [
      { keep: 'true', value: 0 },
      { keep: 'false', value: 1 },
      { keep: 'true', value: 3 },
    ])
  ),
  test3: test_eq(
    [
      { keep: 1, value: 1 },
      { keep: 2, value: 3 },
    ],
    jmespath.search('[?keep>=`1`]', [
      { keep: 0, value: 0 },
      { keep: 1, value: 1 },
      { keep: 2, value: 3 },
    ]),
  ),
  test4: test_eq(
    [],
    jmespath.search("[?keep>='1']", [
      { keep: 0, value: 0 },
      { keep: 1, value: 1 },
      { keep: 2, value: 3 },
    ]),
  ),
  test5: test_eq(
    "[?keep>='1']",
    jmespath.compile("[?keep>='1']").repr(),
  ),
  test6: test_eq(
    '[?keep>=`1`]',
    jmespath.compile('[?keep>=`1`]').repr(),
  ),
  test7: test_eq(
    '[?keep>=`"1"`]',
    jmespath.compile('[?keep>=`"1"`]').repr(),
  ),
  // Bug: brackets between backticks not handled correctly.
  // This is treated as the end of the bracketed expression.
  test8:: test_eq(
    '[?keep>=`["1"]`]',
    jmespath.compile('[?keep>=`["1"]`]').repr(),
  ),
  // Bug: brackets between backticks not handled correctly.
  // This is treated as the end of the bracketed expression.
  test9: test_eq(
    '[?keep>=`{"1": 1}`]',
    jmespath.compile('[?keep>=`{"1": 1}`]').repr(),
  ),
};
test.asTest(results)
