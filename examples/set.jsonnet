local jmespath = import 'jmespath.libsonnet';
local input = {
  foo: ['bar', 'baz'],
};

// Returns this modified document:
// {
//   foo: ['bar', 'qux'],
// };

jmespath.set('foo[1]', input, 'qux')
