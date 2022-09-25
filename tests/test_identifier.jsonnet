local jmespath = import 'jmespath.libsonnet';
local test_eq(expected, actual) = (
  if actual == expected then 'SUCCESS' else
    error '%s != %s' % [actual, expected]
);
local results = {
  test1: test_eq('baz', jmespath.search('foo.bar', { foo: { bar: 'baz' } })),
  test2: test_eq('bar', jmespath.search('foo.bar', { foo: { bar: 'bar' } })),
  test3:
    local data = { foo: { bar: { baz: 'spam' } } };
    local expected = { foo: { bar: { baz: 'eggs' } } };
    test_eq(expected, data + jmespath.patch('foo.bar', { baz: 'eggs' })),
  test4:
    test_eq('baz', jmespath.search(jmespath.compile('foo.bar'),
                                   { foo: { bar: 'baz' } })),
};
std.join('\n', ['%s: %s' % [n, results[n]] for n in std.objectFields(results)])
