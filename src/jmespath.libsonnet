{
  search(expression, data): self.compile(expression).search(data),
  patch(expression, patch): self.compile(expression).patch(patch),
  compile(expression): (
    local token = self.token(expression);
    local next = if std.length(token) == 2 then self.Identity() else
      self.compile(token[2])
    ;
    if std.type(expression) != 'string' then expression else
      if token[0] == 'id' then self.IdSegment(token[1], next)
      else if token[0] == 'index' then self.Index(token[1], next) else error token[0]
  ),
  between(char, lowest, highest):
    std.codepoint(char) >= std.codepoint(lowest)
    && std.codepoint(char) <= std.codepoint(highest),
  idChar(char, first): (
    self.between(char, 'a', 'z') ||
    self.between(char, 'A', 'Z') || (
      if first then false else self.between(char, '0', '9')
    )
  ),
  token(expression):
    if self.idChar(expression[0], first=true) then
      self.idToken(expression)
    else if expression[0] == '[' then (
      self.indexToken(expression)
    ),

  idToken(expression, offset=1):
    local rawRemainder = if expression[offset] == '.' then
      expression[offset + 1:]
    else expression[offset:];
    local remainder = if std.length(rawRemainder) == 0 then [] else [
      rawRemainder,
    ];
    if offset + 1 == std.length(expression) then
      ['id', expression]
    else if self.idChar(expression[offset], first=false) then
      self.idToken(expression, offset + 1)
    else ['id', expression[:offset]] + remainder,

  indexToken(expression):
    local splitResult = std.splitLimit(expression[1:], ']', 2);
    local remainder =
      if std.length(splitResult) == 2 && splitResult[1] == '' then []
      else splitResult[1:];
    ['index', splitResult[0]] + remainder,

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

  Index(index, next): {
    index: std.parseInt(index),
    next: next,
    search(data):
      self.next.search(data[self.index]),
  },

  Identity(): {
    search(data):: data,
    patch(patch):: patch,
  },
}
