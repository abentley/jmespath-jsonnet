local jmespath = import 'jmespath.libsonnet';
local test = import 'test.libsonnet';
local test_eq = test.test_eq;

local results = {
  test1: test_eq('baz', jmespath.search('foo.bar', { foo: { bar: 'baz' } })),
  test2: test_eq('bar', jmespath.search('foo.bar', { foo: { bar: 'bar' } })),
  test3::
    local data = { foo: { bar: { baz: 'spam' } } };
    local expected = { foo: { bar: { baz: 'eggs' } } };
    test_eq(expected, data + jmespath.patch('foo.bar', { baz: 'eggs' })),
  test3a::
    local data = { foo: { bar: { baz: 'spam' } } };
    local expected = { foo: { bar: { baz: 'eggs' } } };
    test_eq(expected, jmespath.doPatch(data, 'foo.bar', { baz: 'eggs' })),
  test4:
    test_eq('baz', jmespath.search(jmespath.compile('foo.bar'),
                                   { foo: { bar: 'baz' } })),
  test5: test_eq(null, jmespath.search('boo.bar', { foo: { bar: 'baz' } })),
  test6: test_eq(null, jmespath.search('foo.far', { foo: { bar: 'baz' } })),
  test7:
    local data = { foo: { bar: { baz: 'spam' } } };
    local expected = { foo: { bar: { baz: 'eggs' } } };
    test_eq(expected, jmespath.set('foo.bar.baz', data, 'eggs')),
  test8::
    test_eq(
      [jmespath.compile('foo.bar'), jmespath.compile('baz')],
      jmespath.extractLast(jmespath.compile('foo.bar.baz'))
    ),
  test9:
    test_eq('ab.cd', jmespath.compile('ab.cd').repr()),
  test10:
    local data = [{ foo: { bar: { baz: 'spam' } } }];
    test_eq(data, jmespath.set('foo.bar.baz', data, 'eggs')),
  test11:
    local data = { foo: { bar: { baz: 'spam' } } };
    local expected = { foo: { bar: { baz: 'spameggs' } } };
    test_eq(expected,
            jmespath.map('foo.bar.baz', data, function(x) x + 'eggs')),
  test12:
    local data = { foo: { bar: { baz: 'spam' } } };
    local expected = { foo: { bar: { baz: 'eggs' } } };
    test_eq(expected,
            jmespath.patch('foo.bar', data, { baz: 'eggs' })),
  test13:
    local data = [{ bar: { baz: 'spam' } }];
    local expected = [{ bar: { baz: 'eggs' } }];
    test_eq(expected,
            jmespath.patch('[0].bar', data, { baz: 'eggs' })),
};
test.asTest(results)
