local jmespath = import 'jmespath.libsonnet';
local test = import 'test.libsonnet';
local test_eq = test.test_eq;

local results = {
  test1: test_eq([1, [2, 3], 4], jmespath.search(
    '*', { '0': 1, '1': [2, 3], '2': 4 }
  )),
  test2: test_eq([1, 4], jmespath.search('*.value', {
    '0': { value: 1 },
    '1': [{ value: 2 }, { value: 3 }],
    '2': { value: 4 },
  })),
  test3: test_eq({ '0': 5, '1': 5, '2': 5 },
                 jmespath.set('*', { '0': 1, '1': [2, 3], '2': 4 }, 5)),
  test4: test_eq(
    { '0': { value: 5 }, '1': [{ value: 2 }, { value: 3 }], '2': { value: 5 } },
    jmespath.set('*.value', {
      '0': { value: 1 },
      '1': [{ value: 2 }, { value: 3 }],
      '2': { value: 4 },
    }, 5)
  ),
  test5: test_eq({ '0': [5], '1': [5], '2': [5] },
                 jmespath.set('*[0]', { '0': [1], '1': [[2, 3]], '2': [4] }, 5)),
  test6: test_eq('*', jmespath.compile('*').repr()),
  test7: test_eq(
    { '0': 5, '1': 5, '2': 5 }, jmespath.map('*', {
      '0': 1,
      '1': [2, 3],
      '2': 4,
    }, function(x) 5)
  ),
};
test.asTest(results)
