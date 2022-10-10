local jmespath = import 'jmespath.libsonnet';
local test = import 'test.libsonnet';
local test_eq = test.test_eq;

local results = {
  test1: test_eq('b', jmespath.search('[1]', ['a', 'b', 'c', 'd', 'e', 'f'])),
  test2: test_eq('b', jmespath.search('x1[1]', { x1: [
    'a',
    'b',
    'c',
    'd',
    'e',
    'f',
  ] })),
  test3: test_eq(
    ['a', 'bb', 'c', 'd', 'e', 'f'], jmespath.doPatch(
      ['a', 'b', 'c', 'd', 'e', 'f'], '[1]', 'b'
    )
  ),
  test4: test_eq(
    [{ b: 'd' }, { b: 'c' }], jmespath.doPatch(
      [{ b: 'c' }, { b: 'c' }], '[0]', { b: 'd' }
    )
  ),
  // patch works as long as the top-level item is an object
  test5:
    local data = { a: [{ b: 'c', d: { e: 'f' } }] };
    test_eq({ a: [{ b: 'c', d: { e: 'g' } }] },
            data + jmespath.patch('a[0]d', { e: 'g' })),
  test6: test_eq(
    [{ b: 'd' }, { b: 'c' }], jmespath.set(
      [{ b: 'c' }, { b: 'c' }], '[0].b', 'd'
    )
  ),
  test7::
    local extracted = jmespath.extractLast(jmespath.compile('[0]b')); test_eq(
      {}, extracted[1].genSetPatch('d'),
    ),
  test8:
    test_eq({
      type: 'index',
      index: 2,
      next: null,
    }, jmespath.compile('[2]')),
  test9:
    test_eq({
      type: 'joiner',
      left: {
        type: 'index',
        index: 1,
        next: {
          type: 'index',
          index: 2,
          next: {
            type: 'terminator',
          },
        },
      },
      next: {
        type: 'index',
        index: 2,
        next: {
          type: 'terminator',
        },
      },
    }, jmespath.compile('[1][2]')),

};
test.asTest(results)
