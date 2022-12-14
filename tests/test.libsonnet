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
  // Given a "suite" (a set of cases associated with a json document) test
  // whether mapping matches the expected value.
  map_test(suite, test_i, result, operation):
    local case = suite.cases[test_i];
    self.test_eq(result, jmespath.map(case.expression, suite.given, operation)),
  // Assert that the results of applying map and searching is the same as
  // searching, then mapping.  This is necessary but not sufficient-- the map
  // method could still be applying the operation in too many cases.
  map_search_test(suite, test_i, operation):
    local case = suite.cases[test_i];
    self.test_eq(operation(case.result), jmespath.search(
      case.expression, jmespath.map(case.expression, suite.given, operation)
    )),
  listTests(results):
    std.join('', ['%s\n' % n for n in std.objectFields(results)]),
  asTest(results): function(testName=null, cmd='render')
    if cmd == 'render' then self.render_results(results, testName)
    else if cmd == 'list' then self.listTests(results),
}
