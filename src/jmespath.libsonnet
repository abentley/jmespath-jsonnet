{
  search(expression, data): self.compile(expression).search(data),
  compile(expression):(
    local splitId = std.splitLimit(expression, '.', 2);
    local next = if std.length(splitId) == 1 then null else
      self.compile(splitId[1])
    ;
    self.IdSegment(splitId[0], next)
  ),
  IdSegment(id, next): {
    id: id,
    next: next,
    search(data)::
      local result = data[id];
      if self.next == null then result else self.next.search(result)
  },
}
