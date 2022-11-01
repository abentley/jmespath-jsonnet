local jmespath = import 'jmespath.libsonnet';
local test = import 'test.libsonnet';
local test_eq = test.test_eq;

local results = {
  test1: test_eq([1, 2, 3, 4], jmespath.search('[]', [1, [2, 3], 4])),
  test2: test_eq([1, 2, 3, 4], jmespath.search('[].value', [
    { value: 1 },
    [{ value: 2 }, { value: 3 }],
    { value: 4 },
  ])),
  test3: test_eq([5, [5, 5], 5], jmespath.set('[]', [1, [2, 3], 4], 5)),
  test4: test_eq('[]', jmespath.compile('[]').repr()),
  test5: test_eq(
    [5, [5, 5], 5], jmespath.map('[]', [1, [2, 3], 4], function(x) 5)
  ),
};
test.asTest(results)
