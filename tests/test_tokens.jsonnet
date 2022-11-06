local jmespath = import 'jmespath.libsonnet';
local test = import 'test.libsonnet';
local test_eq = test.test_eq;

local results = {
  test1: test_eq({
    remainder: null,
    token: { content: 'asdf', name: 'index' },
  }, jmespath._tokens.token('[asdf]')),
  test2: test_eq({
    remainder: null,
    token: { content: '"asdf"', name: 'index' },
  }, jmespath._tokens.token('["asdf"]')),
  test3: test_eq({
    remainder: null,
    token: { content: '"asdf]"', name: 'index' },
  }, jmespath._tokens.token('["asdf]"]')),
  test4: test_eq({
    remainder: null,
    token: { content: '`asdf]`', name: 'index' },
  }, jmespath._tokens.token('[`asdf]`]')),
  test5: test_eq({
    remainder: null,
    token: { content: "'asdf]'", name: 'index' },
  }, jmespath._tokens.token("['asdf]']")),
  test6: test_eq({
    remainder: null,
    token: { content: 'asdf"', name: 'rawString' },
  }, jmespath._tokens.token("'asdf\"'")),
};
test.asTest(results)
