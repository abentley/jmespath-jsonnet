local jmespath = import 'jmespath.libsonnet';
local input = {
  foo: ['bar', 'baz'],
};

// Returns 'baz'
jmespath.search('foo[1]', input)
