local jmespath = import 'jmespath.libsonnet';
local compiled = jmespath.compile('foo[1]');
local input = {
  foo: ['bar', 'baz'],
};

// Returns this modified document:
// {
//   foo: ['bar', 'qux'],
// };

jmespath.set(compiled, input, 'qux')
