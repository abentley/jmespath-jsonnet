{
  test_eq(expected, actual): (
    if actual == expected then 'SUCCESS' else
      error '%s != %s' % [actual, expected]
  ),
  render_results(results, testName=null):
    local testNames = (
      if testName != null then [testName] else std.objectFields(results)
    );
    std.join('\n', [
      '%s: %s' % [n, results[n]]
      for n in testNames
    ]),
  listTests(results):
    std.join('', ['%s\n' % n for n in std.objectFields(results)]),
  asTest(results): function(testName=null, cmd='render')
    if cmd == 'render' then self.render_results(results, testName)
    else if cmd == 'list' then self.listTests(results),
}
