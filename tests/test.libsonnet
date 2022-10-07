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
  asTest(results): function(testName=null) self.render_results(results,
                                                               testName),
}
