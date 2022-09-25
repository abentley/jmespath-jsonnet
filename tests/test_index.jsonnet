local jmespath = import 'jmespath.libsonnet';
local test = import 'test.libsonnet';
local test_eq = test.test_eq;

local results = {
  test1: test_eq('b', jmespath.search('[1]', ['a', 'b', 'c', 'd', 'e', 'f'])),
};
test.render_results(results)
