local tokens = {
  rawToken(name, content, remainder=null): {
    name: name,
    content: content,
    remainder: remainder,
  },

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
    )
    else if expression[0] == '.' then self.subExpressionToken(expression),

  idToken(expression, offset=0):
    local rawRemainder = expression[offset:];
    local remainder =
      if std.length(rawRemainder) == 0 then null else rawRemainder;
    if offset + 1 == std.length(expression) then
      self.rawToken('id', expression)
    else if self.idChar(expression[offset], first=false) then
      self.idToken(expression, offset + 1)
    else self.rawToken('id', expression[:offset], remainder),

  indexToken(expression):
    local splitResult = std.splitLimit(expression[1:], ']', 2);
    local remainder =
      if std.length(splitResult) < 2 || splitResult[1] == '' then null
      else splitResult[1];
    self.rawToken('index', splitResult[0], remainder),

  subExpressionToken(expression):
    self.rawToken('subexpression', expression[1:], null),
};

local exprFactory = {
  ImplIdSegment: {
    search(data)::
      if !std.objectHasAll(data, self.id) then null
      else local result = data[self.id]; if self.next == null then result else self.next.search(result),
    patch(patch)::
      local next = self.next;
      local id = self.id;
      if next != null && !std.objectHasAll(next, 'patch') then
        { [id]: next.doPatch(super[id], patch) }
      else { [self.id]+: if next == null then patch else next.patch(patch) },
    doPatch(data, patch):: data + self.patch(patch),
    genSetPatch(value):: local patch = { [self.id]: value }; patch,
  },
  id(id, next=null, prev=null): self.ImplIdSegment {
    type: 'id',
    id: id,
    next: next,
  },

  ImplIndex: {
    search(data)::
      if self.next == null then data[self.index] else self.next.search(data[self.index]),
    doPatch(data, patch)::
      local patch1 = patch;
      std.mapWithIndex(
        function(i, e)
          if i == self.index then if self.next == null then e + patch1 else self.next.doPatch(e, patch1)
          else e,
        data,
      ),
  },

  index(index, next=null, prev=null):
    local value = self.ImplIndex {
      type: 'index',
      index: std.parseInt(index),
      next: if prev == null then null else next,
    };
    if prev != null then self.joiner(prev, value) else value,

  ImplJoiner: {
    search(data):: self.active.search(data),
    patch(patch):: self.active.patch(patch),
    doPatch(data, patch):: self.active.doPatch(data, patch),
  },

  joiner(left, right): self.ImplJoiner {
    type: 'joiner',
    next: right,
    local tmpnext = self.next,
    local withNext(item, value) =
      item {
        next:
          if !std.objectHas(item, 'next') || item.next == null then value
          else withNext(item.next, value),
      },
    [if left != null then 'left']: withNext(left, tmpnext),
    active:: if std.objectHas(self, 'left') then self.left else self.next,
  },

  subexpression(content, next=null, prev=null):
    self.joiner(right=self.compile2(content, prev), left=prev) {
      type: 'subexpression',
    },
  Terminator(): {
    type: 'terminator',
    search(data):: data,
    patch(patch):: patch,
    doPatch(data, patch):: data + patch,
  },
  // Return an object representing the expression
  // Expression must be a string
  compile(expression, prev=null): (
    local token = tokens.token(expression);
    local next =
      if token.remainder == null then exprFactory.Terminator()
      else self.compile(token.remainder)
    ;
    exprFactory[token.name](token.content, next, prev=prev)
  ),
  compile2(expression, prev=null): (
    local token = tokens.token(expression);
    local next =
      if token.remainder == null then exprFactory.Terminator()
      else self.compile(token.remainder)
    ;
    local expr = exprFactory[token.name](token.content, next=next, prev=prev);
    local result = if token.remainder == null then expr else self.compile2(token.remainder, expr);
    result
  ),
};


local jmespath = {
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
    if compiled.next == null || !std.objectHasAll(compiled.next, 'next') then
      [exprFactory.Terminator(), compiled]
    else [compiled { next: deeper[0] }, deeper[1]],

  compile(expression): if std.type(expression) != 'string' then expression else
    exprFactory.compile2(expression),
};

jmespath
