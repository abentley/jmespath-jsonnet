{
  // Return matching items
  search(expression, data): self.compile(expression).search(data),

  // Return a patch that can be added to an object
  patch(expression, patch): self.compile(expression).patch(patch),

  // Apply a patch to an object
  doPatch(data, expression, patch): self.compile(expression).doPatch(data,
                                                                     patch),

  set(data, expression, value):
    local compiled = self.compile(expression);
    local extracted = self.extractLast(compiled);
    local intermediate = extracted[0];
    local terminal = extracted[1];
    intermediate.doPatch(data, terminal.genSetPatch(value)),

  extractLast(compiled):
    local deeper = self.extractLast(compiled.next);
    if !std.objectHasAll(compiled.next, 'next') then
      [self.Terminator(), compiled]
    else [compiled { next: deeper[0] }, deeper[1]],

  // Return an object representing the expression
  compile(expression): (
    local token = self.token(expression);
    local next = if std.length(token) == 2 then self.Terminator() else
      self.compile(token[2])
    ;
    if std.type(expression) != 'string' then expression else
      if token[0] == 'id' then self.IdSegment(token[1], next)
      else if token[0] == 'index' then self.Index(token[1], next)
      else error token[0]
  ),

  // Return true if a character is in the supplied range (false otherwise)
  between(char, lowest, highest):
    std.codepoint(char) >= std.codepoint(lowest)
    && std.codepoint(char) <= std.codepoint(highest),

  // Return true if the character can be part of an unquoted identifier.
  // first: if true, this would be the first character of the identifier
  idChar(char, first): (
    self.between(char, 'a', 'z') ||
    self.between(char, 'A', 'Z') || (
      if first then false else self.between(char, '0', '9')
    )
  ),

  // Return a token name, text, and remainder
  // Note: the returned text may omit some unneded syntax
  token(expression):
    if self.idChar(expression[0], first=true) then
      self.idToken(expression)
    else if expression[0] == '[' then (
      self.indexToken(expression)
    ),

  idToken(expression, offset=0):
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

  ImplIdSegment: {
    search(data)::
      if !std.objectHasAll(data, self.id) then null
      else self.next.search(data[self.id]),
    patch(patch)::
      local next = self.next;
      local id = self.id;
      if !std.objectHasAll(next, 'patch') then
        { [id]: next.doPatch(super[id], patch) }
      else { [self.id]+: next.patch(patch) },
    doPatch(data, patch):: data + self.patch(patch),
    genSetPatch(value):: local patch = { [self.id]: value }; patch,
  },
  IdSegment(id, next): self.ImplIdSegment {
    type: 'id',
    id: id,
    next: next,
  },

  ImplIndex: {
    search(data)::
      self.next.search(data[self.index]),
    doPatch(data, patch)::
      local patch1 = std.trace(std.toString(data), patch);
      std.mapWithIndex(
        function(i, e)
          if i == self.index then self.next.doPatch(e, patch1)
          else e,
        data,
      ),
  },

  Index(index, next): self.ImplIndex {
    type: 'index',
    index: std.parseInt(index),
    next: next,
  },

  Terminator(): {
    type: 'terminator',
    search(data):: data,
    patch(patch):: patch,
    doPatch(data, patch):: std.trace(std.toString(patch), data) + patch,
  },
}
