local jmespath = import 'jmespath.libsonnet';
local test = import 'test.libsonnet';
local test_eq = test.test_eq;

local results = {
  test1: test_eq(
    [0, 1, 2, 3, 4],
    jmespath.search('[0:5]', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
  ),
  test2: test_eq(
    [5, 6, 7, 8, 9],
    jmespath.search('[5:10]', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
  ),
  test3: test_eq(
    [0, 1, 2, 3, 4],
    jmespath.search('[:5]', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
  ),
  test4: test_eq(
    [5, 6, 7, 8, 9],
    jmespath.search('[5:]', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
  ),
  test5: test_eq(
    [0, 2, 4, 6, 8],
    jmespath.search('[::2]', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
  ),
  test6: test_eq(
    [0, 1, 2, 3],
    jmespath.search('[:-6]', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
  ),
  test7: test_eq(
    [6, 7, 8, 9],
    jmespath.search('[-4:]', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
  ),
  test8: test_eq(
    [9, 7, 5, 3, 1],
    jmespath.search('[::-2]', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
  ),
  test9: test_eq(
    2,
    jmespath.search('[0:5][2]', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
  ),
  test10: test_eq(
    7,
    jmespath.search('[5:10][2]', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
  ),
  test11: test_eq(
    6,
    jmespath.search('[::2][3]', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
  ),
};
test.asTest(results)
