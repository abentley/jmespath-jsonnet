local jmespath = import 'jmespath.libsonnet';
local test = import 'test.libsonnet';
local test_eq = test.test_eq;

local results = {
  test1: test_eq(0, jmespath.search(
    '[*]|[0]', [0, 1]
  )),
  test2: test_eq('bar', jmespath.search(
    '*|[1]', { foo: 'bar', baz: 'qux' }
  )),
  test3: test_eq(0, jmespath.search(
    '|[0]', [0, 1]
  )),
  test4: test_eq('[*]|[0]', jmespath.compile('[*]|[0]').repr()),
  test5: test_eq([5, 1], jmespath.set(
    '[*]|[0]', [0, 1], 5
  )),
  test6: test_eq({ foo: 5, baz: 'qux' }, jmespath.set(
    '*|[1]', { foo: 'bar', baz: 'qux' }, 5
  )),
  test7: test_eq([5, 1], jmespath.set(
    '|[0]', [0, 1], 5
  )),
  test8: test_eq([5, 1], jmespath.set(
    '[:]|[0]', [0, 1], 5
  )),
  test9: test_eq([0, 1, [2, 5]], jmespath.set(
    '[]|[3]', [0, 1, [2, 3]], 5
  )),
};
test.asTest(results)
