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
};
test.asTest(results)
