local countUp(items) = std.range(0, std.length(items) - 1);

local mapContents(data, func, next) =
  if next == null then func(data)
  else next.map(data, func, null, allow_projection=true);

local tokens = {
  rawToken(name, content, remainder=null): {
    token: {
      name: name,
      content: content,
    },
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
    else if expression[0] == '[' then self.bracketToken(expression)
    else if expression[0] == '.' then self.subExpressionToken(expression)
    else if expression[0] == '|' then self.pipeToken(expression)
    else if std.member('=<>!', expression[0:1]) then
      self.comparatorToken(expression)
    else if expression[0] == "'" then self.rawStringToken(expression)
    else if expression[0] == '`' then self.jsonLiteralToken(expression)
    else if expression[0] == '*' then self.objectWildcardToken(expression)
    else error 'Unhandled expression: %s' % std.manifestJson(expression),

  // Return an array of all tokens
  // Expression must be a string
  alltokens(expression, curTokens): (
    local rawToken = self.token(expression);
    local result =
      curTokens + [rawToken.token];
    assert rawToken != null : expression;
    if rawToken.remainder == null then result
    else self.alltokens(rawToken.remainder, result)
  ),

  idToken(expression, offset=0):
    local rawRemainder = expression[offset:];
    local remainder =
      if std.length(rawRemainder) == 0 then null else rawRemainder;
    if offset + 1 == std.length(expression) then
      self.rawToken('id', expression)
    else if self.idChar(expression[offset], first=false) then
      self.idToken(expression, offset + 1)
    else self.rawToken('id', expression[:offset], remainder),

  bracketToken(expression):
    local splitResult = std.splitLimit(expression[1:], ']', 1);
    local remainder = if splitResult[1] == '' then null else splitResult[1];
    local contents = splitResult[0];
    local name =
      if contents[0:1] == '?' then 'filterProjection'
      else if std.member(contents, ':') then 'slice'
      else if contents == '' then 'flatten'
      else if contents == '*' then 'arrayWildcard'
      else 'index';
    self.rawToken(name, contents, remainder),

  objectWildcardToken(expression):
    local rawRemainder = expression[1:];
    local remainder = if rawRemainder == '' then null else rawRemainder;
    self.rawToken('objectWildcard', expression[0], remainder),

  subExpressionToken(expression):
    self.rawToken('subexpression', expression[1:], null),

  pipeToken(expression):
    self.rawToken('pipe', expression[1:], null),

  comparatorToken(expression):
    self.rawToken('comparator', expression, null),

  rawStringToken(expression):
    local splitResult = std.splitLimit(expression[1:], "'", 1);
    local remainder = if splitResult[1] == '' then null else splitResult[1];
    self.rawToken('rawString', splitResult[0], remainder),

  jsonLiteralToken(expression):
    local splitResult = std.splitLimit(expression[1:], '`', 1);
    local remainder = if splitResult[1] == '' then null else splitResult[1];
    self.rawToken('jsonLiteral', splitResult[0], remainder),
};

local exprFactory = {
  ImplMember: {
    searchNext(result, next)::
      if next == null || result == null then result
      else next.search(result, null),
    search(data, next)::
      self.searchNext(self.searchResult(data), next),
  },
  ImplIdSegment: self.ImplMember {
    searchResult(data):
      if std.type(data) != 'object' || !std.objectHasAll(data, self.id) then null
      else data[self.id],

    map(data, func, next, allow_projection)::
      local result = self.searchResult(data);
      if std.type(data) != 'object' || !std.objectHasAll(data, self.id) then data
      else data { [self.id]: mapContents(result, func, next) },
    repr():: self.id,
  },

  // A segment of an identifier.
  id(id, prev=null):
    assert prev == null : std.toString(prev);
    self.ImplIdSegment { type: 'id', id: id },

  ImplIndex: self.ImplMember {
    searchResult(data)::
      if std.type(data) != 'array' then null else data[self.index],

    map(data, func, next, allow_projection)::
      if std.type(data) != 'array' then data else std.mapWithIndex(
        function(i, e)
          if i == self.index then mapContents(e, func, next) else e,
        data,
      ),
    repr():: '[%d]' % self.index,
  },

  maybeJoin(prev, value):
    if prev != null then self.joiner(prev, value) else value,

  // An expression object for looking up by index
  index(index, prev=null):
    self.maybeJoin(prev, self.ImplIndex {
      type: 'index',
      index: std.parseInt(index),
    }),

  ImplProjection: {

    searchResult(data):
      local matching = self.getMatching(data);
      [data[i] for i in countUp(data) if matching[i]],

    searchNext(result, next):
      if result == null || next == null then result else [
        r
        for r in [next.search(v, null) for v in result]
        if r != null
      ],

    search(data, next):
      self.searchNext(self.searchResult(data), next),

    map(data, func, next, allow_projection)::
      local matching = self.getMatching(data);
      if allow_projection then std.mapWithIndex(
        function(i, e) if matching[i] then mapContents(e, func, next) else e,
        data,
      ) else mapContents(data, func, next),
  },

  ImplSlice: self.ImplProjection {
    searchResult(data):
      local length = std.length(data);
      local realStart = if self.start == null then 0
      else if self.start < 0 then length + self.start else self.start;
      local realStop =
        if self.stop == null then length
        else if self.stop < 0 then length + self.stop
        else self.stop;
      local realStep = if self.step == null then 1 else std.abs(self.step);
      local ordered =
        if self.step == null || self.step >= 0 then data else std.reverse(data);
      ordered[realStart:realStop:realStep],

    getMatching(data)::
      local dataIndices = countUp(data);
      local included = std.set(self.searchResult(dataIndices));
      [std.setMember(di, included) for di in dataIndices],

    repr(): '[%s:%s%s]' % [
      if self.start == null then '' else self.start,
      if self.stop == null then '' else self.stop,
      if self.step == null then '' else ':%d' % self.step,
    ],
  },

  flatten(flattenExpr, prev):: self.maybeJoin(prev, self.ImplProjection {

    searchResult(data):: std.foldl(
      function(l, r) l + if std.type(r) == 'array' then r else [r], data, []
    ),

    map(data, func, next, allow_projection)::
      if allow_projection then [
        if std.type(e) == 'array' then [mapContents(f, func, next) for f in e]
        else mapContents(e, func, next)
        for e in data
      ]
      else self.unflatten(data, mapContents(
        self.searchResult(data), func, next
      )),
    unflatten(original, flattened)::
      local current = original[0];
      if std.length(original) == 0 then []
      else if std.type(current) == 'array' then
        local end = std.length(current);
        [flattened[0:end]] + self.unflatten(original[1:], flattened[:end])
      else [flattened[0]] + self.unflatten(original[1:], flattened[1:]),
    repr():: '[]',
  }),

  arrayWildcard(expr, prev):: self.maybeJoin(prev, self.ImplProjection {
    searchResult(data):: data,
    getMatching(data): std.repeat([true], std.length(data)),
    repr():: '[*]',
  }),

  objectWildcard(expr, prev):: self.maybeJoin(prev, self.ImplProjection {
    searchResult(data)::
      if std.type(data) == 'object' then std.objectValues(data),
    map(data, func, next, allow_projection)::
      local fieldsOrder = std.objectFields(data);
      if allow_projection then {
        [f]: mapContents(data[f], func, next)
        for f in fieldsOrder
      }
      else
        local values = mapContents([data[f] for f in fieldsOrder], func, next);
        { [fieldsOrder[i]]: values[i] for i in countUp(fieldsOrder) },
    repr():: '*',
  }),

  slice(sliceExpr, prev=null):
    local splitExpr = std.splitLimit(sliceExpr, ':', 3);
    local intOrNull(expr) = if expr == '' then null else std.parseInt(expr);
    local start = intOrNull(splitExpr[0]);
    local stop =
      if std.length(splitExpr) < 2 then null else intOrNull(splitExpr[1]);
    local step =
      if std.length(splitExpr) < 3 then null else intOrNull(splitExpr[2]);
    self.maybeJoin(prev, self.ImplSlice {
      start: start,
      stop: stop,
      step: step,
    }),

  ImplFilterProjection:: self.ImplProjection {
    getMatching(data):
      [self.comparator.evaluate(d) for d in data],
    repr(): '[?%s]' % self.comparator.repr(),
  },

  filterProjection(sliceExpr, prev=null)::
    local comparator = self.compile(sliceExpr[1:]);
    self.ImplFilterProjection {
      comparator: comparator,
    },

  ImplJoiner: {
    search(data, next):: self.left.search(data, self.right),
    map(data, func, next, allow_projection)::
      self.left.map(data, func, self.right, allow_projection=true),
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

  implPipe: {
    search(data, next):
      local rdata =
        if self.left == null then data else self.left.search(data, null);
      self.right.search(rdata, next),
    map(data, func, next, allow_projection)::
      if self.left == null then self.right.map(data,
                                               func,
                                               null,
                                               allow_projection=false)
      else self.left.map(data, func, self.right, allow_projection=false),
    repr():: std.join('|', [self.left.repr(), self.right.repr()]),
  },

  // Represent both sides of a dot.
  pipe(content, prev):
    self.joiner(prev, self.compile(content, null)) + self.implPipe {
      type: 'pipe',
    },

  ImplJsonLiteral: {
    search(data, next): self.literal,
    repr():
      local contents =
        if std.type(self.literal) == 'string' then std.escapeStringJson(
          self.literal
        )
        else std.toString(self.literal);
      '`%s`' % contents,
  },

  jsonLiteral(content, prev): self.ImplJsonLiteral {
    literal: std.parseJson(content),
  },

  ImplRawString: self.ImplJsonLiteral {
    repr():
      local escaped = std.escapeStringJson(self.literal);
      "'%s'" % escaped[1:std.length(escaped) - 1],
  },

  rawString(string, prev): self.ImplRawString {
    literal: string,
  },

  ImplComparator:: {
    evaluate(data): self.opFunc[self.op](
      self.left.search(data, null), self.right.search(data, null)
    ),
    search(data, next): self.evaluate(data),
    map(data, next, value, allow_projection): data,
    opFunc: {
      '==': function(l, r) l == r,
      '!=': function(l, r) l != r,
      '<': function(l, r)
        if std.type(l) != 'number' || std.type(r) != 'number' then false
        else l < r,
      '<=': function(l, r)
        if std.type(l) != 'number' || std.type(r) != 'number' then false
        else l <= r,
      '>': function(l, r)
        if std.type(l) != 'number' || std.type(r) != 'number' then false
        else l > r,
      '>=': function(l, r)
        if std.type(l) != 'number' || std.type(r) != 'number' then false
        else l >= r,
    },
    repr(): '%s%s%s' % [self.left.repr(), self.op, self.right.repr()],
  },
  comparator(expr, prev)::
    local compile = self.compile;
    self.ImplComparator {
      local op = if expr[1:2] == '=' then expr[0:2] else expr[0:1],
      left: prev,
      right: compile(expr[std.length(op):]),
      op: op,
    },
  // Return an object representing the expression
  // Expression must be a string
  compile(expression, prev=null): (
    std.foldl(
      function(prev, token) self[token.name](token.content, prev=prev),
      tokens.alltokens(expression, []),
      null
    )
  ),
};

local jmespath = {
  // Return matching items
  search(expression, data): self.compile(expression).search(data, null),

  set(expression, data, value): self.map(expression, data, function(x) value),

  map(expression, data, func):
    local compiled = self.compile(expression);
    compiled.map(data, func, null, allow_projection=true),

  patch(expression, data, patch):
    self.map(expression, data, function(x) x + patch),

  compile(expression): if std.type(expression) != 'string' then expression else
    local x = exprFactory.compile(expression); x,
};

jmespath
