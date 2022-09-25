{
  test_eq(expected, actual): (
    if actual == expected then 'SUCCESS' else
      error '%s != %s' % [actual, expected]
  ),
  render_results(results):
    std.join('\n', [
      '%s: %s' % [n, results[n]]
      for n in std.objectFields(results)
    ]),
}
