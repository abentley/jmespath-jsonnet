local jmespath = import 'jmespath.libsonnet';
local compiled = jmespath.compile('foo[1]');
local input = {
  foo: ['bar', 'baz'],
};

// Returns 'baz'
jmespath.search(compiled, input)
