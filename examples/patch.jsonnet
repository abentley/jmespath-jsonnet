local jmespath = import 'jmespath.libsonnet';
local input = {
  foo: [{ bar: 'bar' }, { baz: 'baz' }],
};

// Returns this modified document:
// {
//   foo: [{bar: 'bar'}, {baz: 'baz', qux:'qux'}],
// };

jmespath.patch('foo[1]', input, { qux: 'qux' })
