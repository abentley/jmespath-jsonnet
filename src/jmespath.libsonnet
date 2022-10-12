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
    if self.idChar(expression[0], first=true) then self.idToken(expression)
    else if expression[0] == '[' then self.indexToken(expression)
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
    local splitResult = std.splitLimit(expression[1:], ']', 1);
    local remainder = if splitResult[1] == '' then null else splitResult[1];
    self.rawToken('index', splitResult[0], remainder),

  subExpressionToken(expression):
    self.rawToken('subexpression', expression[1:], null),
};

local exprFactory = {
  ImplIdSegment: {
    search(data, next)::
      if !std.objectHasAll(data, self.id) then null
      else
        local result = data[self.id];
        if next == null then result else next.search(result, null),
    set(data, value, next)::
      local contents =
        if next == null then value else next.set(data[self.id], value, null);
      if !std.objectHasAll(data, self.id) then data
      else data { [self.id]: contents },
    repr():: self.id,
  },

  // A segment of an identifier.
  id(id, prev=null):
    assert prev == null : std.toString(prev);
    self.ImplIdSegment { type: 'id', id: id },

  ImplIndex: {
    search(data, next)::
      if next == null then data[self.index]
      else next.search(data[self.index], next),
    set(data, value, next)::
      std.mapWithIndex(
        function(i, e)
          if i == self.index then
            if next == null then value else next.set(e, value, null)
          else e,
        data,
      ),
    repr():: '[%d]' % self.index,
  },

  // An expression object for looking up by index
  index(index, prev=null):
    local value = self.ImplIndex {
      type: 'index',
      index: std.parseInt(index),
    };
    if prev != null then self.joiner(prev, value) else value,

  ImplJoiner: {
    search(data, next):: self.left.search(data, self.right),
    set(data, value, next):: self.left.set(data, value, self.right),
    repr():: std.join('', [self.left.repr(), self.right.repr()]),
  },

  // A mostly-invisible connector used for joining array accesses into one big
  // connector
  joiner(left, right): self.ImplJoiner {
    type: 'joiner',
    right: right,
    left: left,
  },

  implSubExpression: {
    repr():: std.join('.', [self.left.repr(), self.right.repr()]),
  },

  // Represent both sides of a dot.
  subexpression(content, prev):
    self.joiner(prev, self.compile(content, null)) + self.implSubExpression {
      type: 'subexpression',
    },

  // Return an object representing the expression
  // Expression must be a string
  compile(expression, prev=null): (
    local token = tokens.token(expression);
    local expr = exprFactory[token.name](token.content, prev=prev);
    local result =
      if token.remainder == null then expr
      else self.compile(token.remainder, expr);
    result
  ),
};


local jmespath = {
  // Return matching items
  search(expression, data): self.compile(expression).search(data, null),

  set(expression, data, value):
    local compiled = self.compile(expression);
    compiled.set(data, value, null),

  compile(expression): if std.type(expression) != 'string' then expression else
    local x = exprFactory.compile(expression); x,
};

jmespath
