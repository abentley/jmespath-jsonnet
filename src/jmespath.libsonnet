{
  search(expression, data): self.compile(expression).search(data),
  patch(expression, patch): self.compile(expression).patch(patch),
  compile(expression): (
    local splitId = std.splitLimit(expression, '.', 2);
    local next = if std.length(splitId) == 1 then self.Identity() else
      self.compile(splitId[1])
    ;
    if std.type(expression) == 'string' then
      self.IdSegment(splitId[0], next)
    else expression
  ),
  IdSegment(id, next): {
    id: id,
    next: next,
    search(data)::
      if !std.objectHasAll(data, self.id) then null
      else self.next.search(data[id]),
    patch(patch)::
      local next = self.next;
      { [self.id]+: next.patch(patch) },
  },
  Identity(): {
    search(data):: data,
    patch(patch):: patch,
  },
}
