local test = import 'test.libsonnet';
local tokens = import 'tokens.libsonnet';
local test_eq = test.test_eq;

local results = {
  test1: test_eq({
    remainder: null,
    token: { content: 'asdf', name: 'index' },
  }, tokens.token('[asdf]')),
  test2: test_eq({
    remainder: null,
    token: { content: '"asdf"', name: 'index' },
  }, tokens.token('["asdf"]')),
  test3: test_eq({
    remainder: null,
    token: { content: '"asdf]"', name: 'index' },
  }, tokens.token('["asdf]"]')),
  test4: test_eq({
    remainder: null,
    token: { content: '`asdf]`', name: 'index' },
  }, tokens.token('[`asdf]`]')),
  test5: test_eq({
    remainder: null,
    token: { content: "'asdf]'", name: 'index' },
  }, tokens.token("['asdf]']")),
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
};
test.asTest(results)
