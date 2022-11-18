local jmespath = import 'jmespath.libsonnet';
{
  test_eq(expected, actual): (
    if actual == expected then 'SUCCESS' else
      error '%s != %s' % [std.manifestJson(actual), std.manifestJson(expected)]
  ),
  render_results(results, testName=null):
    local testNames = (
      if testName != null then [testName] else std.objectFields(results)
    );
    std.join('\n', [
      '%s: %s' % [n, results[n]]
      for n in testNames
    ]),
  // Given a "suite" (a set of cases associated with a json document) test
  // whether the values matches the expected value.
  // This format is compatible with jmespath.test
  search_test(suite, test_i):
    local case = suite.cases[test_i];
    self.test_eq(case.result, jmespath.search(case.expression, suite.given)),
  listTests(results):
    std.join('', ['%s\n' % n for n in std.objectFields(results)]),
  asTest(results): function(testName=null, cmd='render')
    if cmd == 'render' then self.render_results(results, testName)
    else if cmd == 'list' then self.listTests(results),
}
